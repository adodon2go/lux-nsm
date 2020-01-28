#!/bin/sh

## This script installs vl3 single domain hello example from https://github.com/tiswanso/examples/tree/joycej_vl3/examples/vl3_basic

# Check prerequisites
sh environment_install.sh

if [ -z "$KUBECONFIG1" ]; then
  echo "$KUBECONFIG1 env variable is undefined"
  exit 1
fi

if [ -z "$KUBECONFIG2" ]; then
  echo "$KUBECONFIG2 env variable is undefined"
  exit 1
fi

# Make sure minikube is not running
minikube stop > /dev/null 2>&1
echo "Make sure minikube is not running"

# Check if Helloworld example is installed
kubectl get pods -A | grep helloworld > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Helloworld example is installed with Kind"
else
    echo "Helloworld example is not installed with Kind"

    # Create a Kind cluster if it doesn't exists
    kind get clusters | grep nsm1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Kind cluster nsm1 already exists"
    else
        kind create cluster --name=nsm1 --kubeconfig=$KUBECONFIG1
    fi

    if [ -d "networkservicemesh" ]; then
        echo "networkservicemesh directory already exists"
        #cd networkservicemesh
    else
        git clone https://github.com/tiswanso/networkservicemesh
        cd networkservicemesh
        git checkout vl3_nsmdns
        cd ..
    fi

    if [ -d "examples" ]; then
        echo "examples directory already exists"
        cd examples
    else
        git clone https://github.com/tiswanso/examples
        cd examples
        git checkout demo_vl3
    fi

    # Pull required images in order for the script to not timeout
    docker pull tiswanso/nsm-init:vl3-inter-domain2
    docker pull docker.io/istio/examples-helloworld-v1
    docker pull tiswanso/kali_testssl
    docker pull k8s.gcr.io/coredns:1.2.6
    kind load docker-image k8s.gcr.io/coredns:1.2.6 --name=nsm1
    
    examples/vl3_basic/scripts/demo_vl3_single.sh --kconf_clus1=$KUBECONFIG1 --hello
fi

