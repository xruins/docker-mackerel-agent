# docker-mackerel-agent

[![Docker Image Size](https://img.shields.io/docker/image-size/ruins/mackerel-agent/latest)](https://hub.docker.com/r/ruins/mackerel-agent)
[![latest build](https://github.com/xruins/docker-mackerel-agent/actions/workflows/latest-build.yml/badge.svg)](https://github.com/xruins/docker-mackerel-agent/actions/workflows/latest-build.yml)
[![latest-light build](https://github.com/xruins/docker-mackerel-agent/actions/workflows/latest-light-build.yml/badge.svg)](https://github.com/xruins/docker-mackerel-agent/actions/workflows/latest-light-build.yml)

# Usage

Visit https://github.com/mackerelio/docker-mackerel-agent/blob/master/README.md for basic usage.

# Compare

| Image                                                                         | Official | Image size(approx.) | Support arm64/armv7 | Bundled official plugins [^1] | Plugin installation |
| ----------------------------------------------------------------------------- | -------- | ------------------- | ------------------- | ------------------------ | ------------------- |
| [mackerelio/mackerel-agent](https://hub.docker.com/r/mackerel/mackerel-agent) | ✓        | 390MB               | ✘                   | ✓                        | ✘                   |
| ruins/mackerel-agent:latest                                                   | ✘        | 240MB               | ✓                   | ✓                        | ✓                   |
| ruins/mackerel-agent:latest-light                                             | ✘        | 80MB                | ✓                   | ✘                        | ✓                   |

[^1]: it means all plugins of [mackerelio/mackerel-agent-plugins](https://github.com/mackerelio/mackerel-agent-plugins) and [mackerelio/go-check-plugins](https://github.com/mackerelio/go-check-plugins) are executable in PATH.
## Plugin installation

By setting `mackerel_plugins` for environment variable, install plugins when start docker image.

``` sh
docker run -h `hostname` \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/mackerel-agent/:/var/lib/mackerel-agent/ \
  -e 'apikey=<APIKEY>' \
  -e 'enable_docker_plugin=1' \
  -e 'mackerel_plugins="xruins/mackerel-plugins-hddtemp xruins/mackerel-plugins-nicehash-stats"' \
  --name mackerel-agent \
  -d \
  mackerel/mackerel-agent
```

The repository to specify in `mackerel_plugins` must be compatible to installation with `mkr plugin install`.
