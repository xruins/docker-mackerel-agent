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
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    git clone --depth=1 https://github.com/mackerelio/go-check-plugins /go/src/github.com/mackerelio/go-check-plugins && \
    plugins=$(find /go/src/github.com/mackerelio/go-check-plugins -name "check-*" -type d) && \
    for dir in ${plugins}; \
    do \
    cd ${dir}; \
    pluginname=$(basename ${PWD}); \
    go build -ldflags="-w -s" -o /artifacts/${pluginname}; \
    done

FROM alpine
LABEL org.opencontainers.image.source https://github.com/xruins/docker-mackerel-agent
LABEL revisions.docker-mackerel-agent $HASH_DOCKER_MACKEREL_AGENT
LABEL revisions.mackerel-agent $HASH_MACKEREL_AGENT
LABEL revisions.mackerel-agent-plugins $HASH_MACKEREL_PLUGINS
LABEL revisions.mackerel-check-plugins $HASH_MACKEREL_CHECK_PLUGINS
COPY --chmod=755 --from=builder /artifacts/* /usr/bin/
COPY --chmod=755 docker-mackerel-agent/startup.sh wrapper.sh /
RUN apk add --no-cache libc6-compat docker
ENV PATH $PATH:/opt/mackerel-agent/plugins/bin
CMD ["/wrapper.sh"]
