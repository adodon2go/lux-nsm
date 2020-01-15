#!/bin/sh

## This script installs Golang locally (if it is not already installed)
## Tested on Ubuntu 18.04
GOLANG_VERSION=1.13.5

# Check if golang is installed
go version > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Golang is installed"
else
    echo "Golang is not installed"
    GOPATH=$HOME/go
    GOROOT=$HOME/GoInstall
    
    mkdir -p $GOPATH
    mkdir -p $GOROOT
    
    cd $GOROOT
    curl -O https://storage.googleapis.com/golang/go$GOLANG_VERSION.linux-amd64.tar.gz
    tar -zxf go$GOLANG_VERSION.linux-amd64.tar.gz
    rm -rf go$GOLANG_VERSION.linux-amd64.tar.gz
    
    # Add environment variables to bashrc for persistence
    echo "export GOPATH=$GOPATH" >> ~/.bashrc
    echo "export GOROOT=$GOROOT/go" >> ~/.bashrc
    echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin" >> ~/.bashrc

    echo "you need to manually add command 'source ~/.bashrc' into the shell to pick up latest environment changes"
fi


