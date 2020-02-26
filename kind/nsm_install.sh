#!/bin/sh

## This script installs NSM inside KinD (Kubernetes in Docker)

# Make sure minikube is not running
minikube stop > /dev/null 2>&1
echo "Checking that Minikube is not running"

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

# Check if KinD is installed
kind version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "KinD is installed"
else
    echo "KinD is not installed"
    GO111MODULE="on" go get sigs.k8s.io/kind@v0.7.0
fi

# Check if NSM is installed
kubectl get pods -A | grep nsmgr > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NSM is installed with KinD"
else
    echo "NSM is not installed with KinD"
    if [ -d "networkservicemesh" ]; then
        echo "networkservicemesh directory already exists"
        cd networkservicemesh
    else
        git clone https://github.com/networkservicemesh/networkservicemesh.git
        cp ../nsm_patch.diff networkservicemesh/
        cp testing_patch.diff networkservicemesh/
        cd networkservicemesh
        git apply nsm_patch.diff
        if [ $? -ne 0 ]; then
            echo "Applying an NSM patch failed"
            exit 1
        fi
        git apply testing_patch.diff
        if [ $? -ne 0 ]; then
            echo "Applying an NSM patch (for testing) failed"
            exit 1
        fi
    fi

    make k8s-build
    make k8s-save
    make kind-start

    TILLER_IMAGE=gcr.io/kubernetes-helm/tiller:v2.16.1
    docker pull $TILLER_IMAGE
    # load Tiller image into KinD
    kind load docker-image $TILLER_IMAGE --name nsm

    make k8s-load-images
    make helm-init
    make helm-install-nsm
fi

