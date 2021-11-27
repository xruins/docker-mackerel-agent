#!/bin/sh

for plugin in ${MACKEREL_PLUGINS[@]}; do
    echo "install ${plugin}..."
    mkr install ${plugin}
done

/startup.sh