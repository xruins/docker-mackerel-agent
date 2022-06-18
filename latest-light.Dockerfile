FROM --platform=$TARGETPLATFORM golang AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG HASH_DOCKER_MACKEREL_AGENT
ARG HASH_MACKEREL_AGENT

WORKDIR /go/src/github.com/mackerelio/mackerel-agent

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    export GOOS=$(echo ${TARGETPLATFORM} | cut -d'/' -f1) && \
    export GOARCH=$(echo ${TARGETPLATFORM} | cut -d'/' -f2) && \
    export GOARM=$(echo ${TARGETPLATFORM} | cut -d'/' -f3 | cut -c2) && \
    export CGO_ENABLED=0 && \
    echo "[build info]\n\
        TARGETPLATFORM: ${TARGETPLATFORM}\n\
        BUILDPLATFORM: ${BUILDPLATFORM}\n\
        GOOS: ${GOOS}\n\
        GOARCH: ${GOARCH}\n\
        GOARM: ${GOARM}\n" && \
    git clone --depth=1 https://github.com/mackerelio/mackerel-agent /go/src/github.com/mackerelio/mackerel-agent && \
    mkdir /artifacts && \
    go build -ldflags="-w -s" -o /artifacts/mackerel-agent && \
    git clone --depth=1 https://github.com/mackerelio/mkr /go/src/github.com/mackerelio/mkr && \
    cd /go/src/github.com/mackerelio/mkr && \
    go build -ldflags="-w -s" -o /artifacts/mkr

FROM alpine
LABEL "org.opencontainers.image.source"="https://github.com/xruins/docker-mackerel-agent" \
    "revisions.docker-mackerel-agent"=$HASH_DOCKER_MACKEREL_AGENT \
    "revisions.mackerel-agent"=$HASH_MACKEREL_AGENT
COPY --chmod=755 --from=builder /artifacts/* /usr/bin/
COPY --chmod=755 docker-mackerel-agent/startup.sh wrapper.sh /
ENV PATH $PATH:/opt/mackerel-agent/plugins/bin
CMD ["/wrapper.sh"]
