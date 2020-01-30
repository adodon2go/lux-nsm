#!/bin/sh

## This script installs Docker Community Edition locally (if it is not already installed)
## Tested on Ubuntu 18.04
DOCKER_VERSION=18.06.3~ce~3-0~ubuntu

# Check if Docker is installed
docker version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Docker CE is installed"
else
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
    sudo apt-get install docker-ce=$DOCKER_VERSION
    sudo groupadd docker
    sudo usermod -aG docker $USER
    echo "Log out and log back in so that your Docker group membership is re-evaluated"
    # exclude Docker from being updated on Linux
    sudo apt-mark hold docker && sudo apt-get upgrade
fi

