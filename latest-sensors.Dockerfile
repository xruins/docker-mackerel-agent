FROM --platform=$TARGETPLATFORM golang AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

WORKDIR /go/src/github.com/mackerelio/mackerel-agent

ARG HASH_DOCKER_MACKEREL_AGENT
ARG HASH_MACKEREL_AGENT
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    export GOOS=$(echo ${TARGETPLATFORM} | cut -d'/' -f1) && \
    export GOARCH=$(echo ${TARGETPLATFORM} | cut -d'/' -f2) && \
    export GOARM=$(echo ${TARGETPLATFORM} | cut -d'/' -f3 | cut -c2) && \
    echo "[build info]\n\
        TARGETPLATFORM: ${TARGETPLATFORM}\n\
        BUILDPLATFORM: ${BUILDPLATFORM}\n\
        GOOS: ${GOOS}\n\
        GOARCH: ${GOARCH}\n\
        GOARM: ${GOARM}\n" && \
    git clone --depth=1 https://github.com/mackerelio/mackerel-agent /go/src/github.com/mackerelio/mackerel-agent && \
    mkdir /artifacts && \
    go build -ldflags="-w -s" -o /artifacts/mackerel-agent
    
ARG HASH_MACKEREL_PLUGINS
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    git clone --depth=1 https://github.com/mackerelio/mkr /go/src/github.com/mackerelio/mkr && \
    cd /go/src/github.com/mackerelio/mkr && \
    go build -ldflags="-w -s" -o /artifacts/mkr && \
    git clone --depth=1 https://github.com/mackerelio/mackerel-agent-plugins /go/src/github.com/mackerelio/mackerel-agent-plugins && \
    plugins=$(find /go/src/github.com/mackerelio/mackerel-agent-plugins -name "mackerel-plugin-*" -type d) && \
    for dir in ${plugins}; \
    do \
    cd ${dir}; \
    pluginname=$(basename ${PWD}); \
    go build -ldflags="-w -s" -o /artifacts/${pluginname}; \
    done
    
ARG HASH_MACKEREL_CHECK_PLUGINS
RU  --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    git clone --depth=1 https://github.com/mackerelio/go-check-plugins /go/src/github.com/mackerelio/go-check-plugins && \
    plugins=$(find /go/src/github.com/mackerelio/go-check-plugins -name "check-*" -type d) && \
    for dir in ${plugins}; \
    do \
    cd ${dir}; \
    pluginname=$(basename ${PWD}); \
    go build -ldflags="-w -s" -o /artifacts/${pluginname}; \
    done

FROM debian:stable-slim
LABEL org.opencontainers.image.source https://github.com/xruins/docker-mackerel-agent \
    "revisions.docker-mackerel-agent"=$HASH_DOCKER_MACKEREL_AGENT \
    "revisions.mackerel-agent"=$HASH_MACKEREL_AGENT \
    "revisions.mackerel-agent-plugins"=$HASH_MACKEREL_PLUGINS \
    "revisions.mackerel-check-plugins"=$HASH_MACKEREL_CHECK_PLUGINS
COPY --from=builder --chmod=755 /artifacts/* /usr/bin/
# workaround for "x509: certificate signed by unknown authority" error
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --chmod=755 docker-mackerel-agent/startup.sh wrapper.sh /
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg2 lsb-release net-tools
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    iproute2 \
    jq \
    docker-ce-cli \
    lm-sensors \
    smartmontools \
    hddtemp &&\
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*
ENV PATH $PATH:/opt/mackerel-agent/plugins/bin
CMD ["/wrapper.sh"]
