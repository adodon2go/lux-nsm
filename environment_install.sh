#!/bin/sh

## This script provides initial setup for running a single-node Kubernetes cluster (minikube)
## If inside Luxoft network (environment variable LUXOFT_ENV=some_value is defined) you need first to authenticate through FW Checkpoint
## The script checks if virtualization support is enabled in Linux, curl/kubectl/VirtualBox/minikube are installed (and if not installs them)
## This script was tested on : Ubuntu 18.04

#In case you receive "Got permission denied while trying to connect to the Docker daemon socket at unix" when running Docker client commands:
# > sudo usermod -aG docker $(whoami)
# and reconnect to new SSH terminal for changes to take effect

if [ -z "$LUXOFT_ENV" ]; then
  echo "LUXOFT_ENV is undefined"
else
  echo "LUXOFT_ENV is defined: proceed to Luxoft FW Checkpoint login"
  
  # Add an alias in ~/.bashrc  (https://github.com/felixb/cpfw-login)
  # alias myproxy='cpfw-login_amd64 --user adodon'

  # Check if cpfw-login_amd64 is installed
  cpfw-login_amd64 --help > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "cpfw-login_amd64 is installed"
  else
    echo "cpfw-login_amd64 is not installed"
    sudo cp cpfw-login_amd64 /usr/local/bin/
  fi

  cpfw-login_amd64 --user adodon
  while [ $? -ne 0 ]; do
    # Put a sleep to prevent flooding of output in case cpfw-login_amd64 is not found in $PATH
    sleep 1
    cpfw-login_amd64 --user adodon
  done
  
  FILE=/usr/local/share/ca-certificates/Luxoft-Root-CA.crt
  if [ -f "$FILE" ]; then
    echo "$FILE exist"
  else 
    echo "$FILE does not exist"
    sudo mkdir -p /usr/local/share/ca-certificates
    sudo cp certs/* /usr/local/share/ca-certificates/
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
# vboxmanage --version > /dev/null 2>&1
# if [ $? -eq 0 ]; then
    # echo "VirtualBox already installed"
# else
    # echo "VirtualBox is not installed"
    # #Add the following line to your /etc/apt/sources.list
    # sudo add-apt-repository "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"

    # wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    # wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
    # sudo apt-get update
    # sudo apt-get install -y virtualbox-6.0
# fi

# Check if minikube is installed
# minikube > /dev/null 2>&1
# if [ $? -eq 0 ]; then
    # echo "minikube already installed"
# else
    # echo "minikube is not installed"
    
    # curl -O https://storage.googleapis.com/minikube/releases/v1.5.2/minikube-linux-amd64 && chmod +x minikube-linux-amd64
    # sudo mkdir -p /usr/local/bin/
    # sudo install -v minikube-linux-amd64 /usr/local/bin/minikube
    # rm minikube-linux-amd64
    
    # if [ -z "$LUXOFT_ENV" ]; then
        # echo "LUXOFT_ENV is undefined"
    # else
        # echo "LUXOFT_ENV is defined: copy Luxoft root CA into minikube"
        # mkdir -p $HOME/.minikube/files/etc/ssl/certs
        # cp /usr/local/share/ca-certificates/*.crt ~/.minikube/files/etc/ssl/certs
    # fi
# fi

sh golang_install.sh
sh docker_ce_install.sh
sh helm_install.sh

