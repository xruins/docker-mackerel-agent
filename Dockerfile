FROM --platform=$TARGETPLATFORM golang AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

WORKDIR /go/src/github.com/mackerelio/mackerel-agent

RUN export GOOS=$(${TARGETPLATFORM} | cut -d'/' -f1) && \
    export GOARCH=$(${TARGETPLATFORM} | cut -d'/' -f2) && \
    export GOARM=$(${TARGETPLATFORM} | cut -d'/' -f3 | cut -c2) && \
    echo "[build info]\n\
        TARGETPLATFORM: ${TARGETPLATFORM}\n\
        BUILDPLATFORM: ${BUILDPLATFORM}\n\
        GOOS: ${GOOS}\n\
        GOARCH: ${GOARCH}\n\
        GOARM: ${GOARM}\n" && \
    git clone --depth=1 https://github.com/mackerelio/mackerel-agent /go/src/github.com/mackerelio/mackerel-agent && \
    mkdir /artifacts && \
    go build -ldflags="-w -s" -o /artifacts/mackerel-agent && \
    ls -la /artifacts && \
    git clone --depth=1 https://github.com/mackerelio/mackerel-agent-plugins /go/src/github.com/mackerelio/mackerel-agent-plugins && \
    plugins=$(find /go/src/github.com/mackerelio/mackerel-agent-plugins -name "mackerel-plugins-*" -type d) && \
    for dir in ${plugins}; \
    do \
    cd ${dir}; \
    pluginname=$(basename ${PWD}); \
    go build -ldflags="-w -s" -o /artifacts/${pluginname}; \
    done

FROM alpine
COPY --from=builder /artifacts/* /usr/local/bin/
COPY docker-mackerel-agent/startup.sh /usr/local/bin/
RUN chmod -R 755 /usr/local/bin/
CMD ["/usr/local/bin/startup.sh"]
