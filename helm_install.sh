#!/bin/sh

## This script installs Helm locally (if it is not already installed)
## Tested on Ubuntu 18.04
HELM_VERSION=v3.3.1

# Check if Helm is installed
helm --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Helm is installed"
else
    echo "Helm is not installed"
    curl -O https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz
    tar -zxvf helm-$HELM_VERSION-linux-amd64.tar.gz
    sudo cp linux-amd64/helm /usr/local/bin

    #Cleanup
    rm -rf helm-$HELM_VERSION-linux-amd64.tar.gz linux-amd64/
fi
