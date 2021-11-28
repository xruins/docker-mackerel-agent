#!/bin/sh

for plugin in ${mackerel_plugins}; do
    echo "install ${plugin}..."
    mkr plugin install ${plugin}
done

/startup.sh