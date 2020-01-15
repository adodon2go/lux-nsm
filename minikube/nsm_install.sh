#!/bin/sh

## This script installs NSM inside Minikube

# Make sure we have initial minikube setup up & running
# Check if minikube is running
minikube status | grep Running > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "minikube already running"
else
    echo "minikube is not running"
    minikube start > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "minikube is running"
	else
		echo "minikube is not installed"
		sh ../environment_install.sh
	fi
fi

if [ -d "networkservicemesh" ]; then
  echo "Cleaning up networkservicemesh directory"
  rm -rf networkservicemesh
fi

# Check if NSM is installed
kubectl get pods -A | grep nsm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NSM is installed"
else
    echo "NSM is not installed"
    git clone https://github.com/networkservicemesh/networkservicemesh.git
    cp ../nsm_patch.diff networkservicemesh/
    cd networkservicemesh && git apply nsm_patch.diff
    make helm-init
    make helm-install-nsm
fi


