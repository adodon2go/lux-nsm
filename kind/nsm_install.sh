#!/bin/sh

## This script installs NSM inside Kind (Kubernetes in Docker)

# Make sure minikube is not running
minikube stop > /dev/null 2>&1
echo "Checking that Minikube is not running"

if [ -d "networkservicemesh" ]; then
  echo "Cleaning up networkservicemesh directory"
  rm -rf networkservicemesh
fi

# Check if kubectl is installed
kubectl > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "kubectl is installed"
else
    echo "kubectl is not installed"
    WORKINGDIR=`pwd`
    cd ..
    sh environment_install.sh
    cd $WORKINGDIR
fi

# Check if NSM is installed
kubectl get pods -A | grep nsm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NSM is installed with Kind"
else
    echo "NSM is not installed with Kind"
    git clone https://github.com/networkservicemesh/networkservicemesh.git
    cp ../nsm_patch.diff networkservicemesh/
    cd networkservicemesh && git apply nsm_patch.diff

    if [ -z "$LUXOFT_ENV" ]; then
        echo "LUXOFT_ENV is undefined"
    else
        echo "LUXOFT_ENV is defined: proceed to Luxoft FW Checkpoint login"

        # Add an alias in ~/.bashrc  (https://github.com/felixb/cpfw-login)
        # alias myproxy='cpfw-login_amd64 --user adodon'
        cpfw-login_amd64 --user adodon
        while [ $? -ne 0 ]; do
            cpfw-login_amd64 --user adodon
        done

        cd ..
        cp kind_patch.diff networkservicemesh/
        cd networkservicemesh && git apply kind_patch.diff
    fi

    make k8s-build
    make k8s-save
    make kind-start

    if [ -z "$LUXOFT_ENV" ]; then
        echo "LUXOFT_ENV is undefined"
    else
        echo "LUXOFT_ENV is defined"
        # TODO; automatize this (extract container names through 'docker ps| grep kind' command)
        docker exec -it nsm-control-plane /usr/sbin/update-ca-certificates
        docker exec -it nsm-worker /usr/sbin/update-ca-certificates
        docker exec -it nsm-worker2 /usr/sbin/update-ca-certificates
    fi

    make k8s-load-images
    make helm-init
    make helm-install-nsm
fi

