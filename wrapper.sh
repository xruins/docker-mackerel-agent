#!/bin/sh

for plugin in ${mackerel_plugins}; do
    echo "install ${plugin}..."
    mkr install ${plugin}
done

/startup.sh