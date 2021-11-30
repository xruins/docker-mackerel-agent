FROM --platform=$TARGETPLATFORM golang AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

WORKDIR /go/src/github.com/mackerelio/mackerel-agent

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
    done && \
    git clone --depth=1 https://github.com/mackerelio/go-check-plugins /go/src/github.com/mackerelio/go-check-plugins && \
    plugins=$(find /go/src/github.com/mackerelio/go-check-plugins -name "check-*" -type d) && \
    for dir in ${plugins}; \
    do \
    cd ${dir}; \
    pluginname=$(basename ${PWD}); \
    go build -ldflags="-w -s" -o /artifacts/${pluginname}; \
    done

FROM alpine
COPY --from=builder /artifacts/* /usr/bin/
COPY docker-mackerel-agent/startup.sh /startup.sh
COPY wrapper.sh /wrapper.sh
RUN chmod -R 755 \
    /startup.sh \
    /wrapper.sh \
    /usr/bin/mackerel-* \
    /usr/bin/check-* \
    /usr/bin/mkr && \
    apk add --no-cache libc6-compat docker
ENV PATH $PATH:/opt/mackerel-agent/plugins/bin
CMD ["/wrapper.sh"]
