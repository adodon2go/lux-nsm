#!/bin/sh

## This script installs NSM inside Minikube

# Make sure we have initial minikube setup up & running
sh environment_install.sh

# Check if helm is installed
helm --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "helm is installed"
else
    echo "helm is not installed"
    curl -O  https://get.helm.sh/helm-v2.16.1-linux-amd64.tar.gz
    tar -zxvf helm-v2.16.1-linux-amd64.tar.gz
    sudo cp linux-amd64/helm /usr/local/bin/
    rm -rf linux-amd64 helm-v2.16.1-linux-amd64.tar.gz
fi

# Check if NSM is installed
kubectl get pods -A | grep nsm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NSM is installed"
else
    echo "NSM is not installed"
    git clone https://github.com/networkservicemesh/networkservicemesh.git
    cp nsm_patch.diff networkservicemesh/
    cd networkservicemesh && git apply nsm_patch.diff
    make helm-init
    make helm-install-nsm
fi

if [ -d "networkservicemesh" ]; then
  echo "Cleaning up networkservicemesh directory"
  rm -rf networkservicemesh
fi

