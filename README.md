# docker-mackerel-agent

[![CircleCI](https://circleci.com/gh/xruins/docker-mackerel-agent/tree/master.svg?style=svg)](https://circleci.com/gh/xruins/docker-mackerel-agent/tree/master)

# Usage

Visit https://github.com/mackerelio/docker-mackerel-agent/blob/master/README.md for basic usage.

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