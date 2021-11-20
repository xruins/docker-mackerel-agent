FROM --platform=$TARGETPLATFORM golang AS builder


ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "build an image for ${TARGETPLATFORM}"
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"

RUN export ARR=$(echo ${TARGETPLATFORM} | tr "/" "\n")
RUN export GOOS=$ARR[0]
RUN export GOARCH=$ARR[1]
RUN export GOARM=$ARR[2]
RUN echo "build image. GOOS: ${GOOS}, GOARCH:${GOARCH}, GOARM:${GOARM}"

WORKDIR /go/src/github.com/mackerelio/mackerel-agent

RUN git clone --depth=1 https://github.com/mackerelio/mackerel-agent /go/src/github.com/mackerelio/mackerel-agent && \
    mkdir /artifacts && \
    go build -ldflags="-w -s" -o /artifacts/mackerel-agent && \
    ls -la /artifacts

RUN go env

RUN git clone --depth=1 https://github.com/mackerelio/mackerel-agent-plugins /go/src/github.com/mackerelio/mackerel-agent-plugins
RUN plugins=$(find /go/src/github.com/mackerelio/mackerel-agent-plugins -name "mackerel-plugins-*" -type d) && \
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
