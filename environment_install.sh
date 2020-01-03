#!/bin/sh

## This script provides initial setup for running a single-node Kubernetes cluster (minikube)
## If inside Luxoft network (environment variable LUXOFT_ENV=some_value is defined) you need first to authenticate through FW Checkpoint
## The script checks if virtualization support is enabled in Linux, curl/kubectl/VirtualBox/minikube are installed (and if not installs them)
## This script was tested on : Ubuntu 18.04

if [ -z "$LUXOFT_ENV" ]; then
  echo "LUXOFT_ENV is undefined"
else
  echo "LUXOFT_ENV is defined: proceed to Luxoft FW Checkpoint login"
  
  # Add an alias in ~/.bashrc  (https://github.com/felixb/cpfw-login)
  # alias myproxy='cpfw-login_amd64 --user adodon'
  cpfw-login_amd64 --user adodon
  
  FILE=/usr/local/share/ca-certificates/luxoft/luxoft_root_ca.crt
  if [ -f "$FILE" ]; then
    echo "$FILE exist"
  else 
    echo "$FILE does not exist"
    sudo mkdir /usr/local/share/ca-certificates/luxoft
    sudo cp root_ca.crt /usr/local/share/ca-certificates/luxoft/luxoft_root_ca.crt
    sudo update-ca-certificates
  fi

fi

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

#Installing Virtual Box

# Check if VirtualBox is installed
vboxmanage --version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "VirtualBox already installed"
else
    echo "VirtualBox is not installed"
    #Add the following line to your /etc/apt/sources.list
    sudo add-apt-repository "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"

    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install -y virtualbox-6.0
fi

# Check if minikube is installed
minikube > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "minikube already installed"
else
    echo "minikube is not installed"
    
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.5.2/minikube-linux-amd64 && chmod +x minikube
    sudo mkdir -p /usr/local/bin/
    sudo install minikube /usr/local/bin/
    rm minikube
    
    if [ -z "$LUXOFT_ENV" ]; then
        echo "LUXOFT_ENV is undefined"
    else
        echo "LUXOFT_ENV is defined: copy Luxoft root CA into minikube"
        mkdir -p $HOME/.minikube/files/etc/ssl/certs
        sudo cp /usr/local/share/ca-certificates/luxoft/luxoft_root_ca.crt ~/.minikube/files/etc/ssl/certs
    fi
fi


# Check if minikube is running
minikube status | grep Running > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "minikube already running"
else
    echo "minikube is not running"
    minikube start
fi
