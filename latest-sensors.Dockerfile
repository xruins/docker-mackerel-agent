FROM --platform=$TARGETPLATFORM golang AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

WORKDIR /go/src/github.com/mackerelio/mackerel-agent

ARG HASH_MACKEREL_AGENT
RUN export GOOS=$(echo ${TARGETPLATFORM} | cut -d'/' -f1) && \
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
RUN git clone --depth=1 https://github.com/mackerelio/mkr /go/src/github.com/mackerelio/mkr && \
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
RUN git clone --depth=1 https://github.com/mackerelio/go-check-plugins /go/src/github.com/mackerelio/go-check-plugins && \
    plugins=$(find /go/src/github.com/mackerelio/go-check-plugins -name "check-*" -type d) && \
    for dir in ${plugins}; \
    do \
    cd ${dir}; \
    pluginname=$(basename ${PWD}); \
    go build -ldflags="-w -s" -o /artifacts/${pluginname}; \
    done

FROM debian:stable-slim
LABEL org.opencontainers.image.source https://github.com/xruins/docker-mackerel-agent
COPY --from=builder /artifacts/* /usr/bin/
# workaround for "x509: certificate signed by unknown authority" error
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY docker-mackerel-agent/startup.sh /startup.sh
COPY wrapper.sh /wrapper.sh
RUN chmod -R 755 \
    /startup.sh \
    /wrapper.sh \
    /usr/bin/mackerel-* \
    /usr/bin/check-* \
    /usr/bin/mkr && \
    apt-get update && \
    apt-get install --no-install-recommends -y lm-sensors smartmontools hddtemp && \
    apt-get clean && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*
ENV PATH $PATH:/opt/mackerel-agent/plugins/bin
CMD ["/wrapper.sh"]
