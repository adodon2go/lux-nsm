#!/bin/sh

# Check virtualization support in Linux
if [ -z "$(grep -E --color 'vmx|svm' /proc/cpuinfo)" ]; then
    echo "No Virtualization support in Linux"
    exit  1
else
    echo "Virtualization support is enabled"
fi

# Check if curl is installed
curl --version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "curl is installed"
else
    echo "curl is not installed"
    sudo apt install -y curl
fi

# Check if kubectl is installed
kubectl > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "kubectl is installed"
else
    echo "kubectl is not installed"
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.16.0/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    # Add below line in ~/.bashrc for persistence
    echo "source <(kubectl completion bash)" >> ~/.bashrc
fi

# Check if golang is installed
go version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Golang is installed"
else
    echo "Golang is not installed: please install it."
    exit  1
fi

# Check if kind is installed
kind --version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "kind is installed"
else
    GO111MODULE="on" go get sigs.k8s.io/kind@v0.7.0
    cp $GOPATH/bin/kind /usr/local/bin/
fi

# Check if kind cluster config files are in place
KUBECONFIG1=$HOME/.kind/cluster/nsm1/config
KUBECONFIG2=$HOME/.kind/cluster/nsm2/config

if [ -f "$KUBECONFIG1" ]; then
    echo "$KUBECONFIG1 exist"
else 
    echo "$KUBECONFIG1 does not exist"
    mkdir -p $HOME/.kind/cluster/nsm1
    mkdir -p $HOME/.kind/cluster/nsm2
    
    cp config $HOME/.kind/cluster/nsm1
    cp config $HOME/.kind/cluster/nsm2
    
    echo "You need to add KUBECONFIG1 and KUBECONFIG2 as environment variables"
  fi


