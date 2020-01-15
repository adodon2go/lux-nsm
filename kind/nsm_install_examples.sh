#!/bin/sh

## This script installs NSM Examples inside Kind: icmp-responder, vpn, vpp-icmp-responder

# Make sure minikube is not running
minikube stop

# Make sure we have initial Kind NSM setup up & running
kubectl get pods -A | grep nsm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NSM is installed with Kind"
else
    echo "NSM is not installed with Kind: run nsm_install.sh script first"
	sh nsm_install.sh
fi

# Check if NSM example icmp-responder is installed
kubectl get pods -A | grep icmp-responder > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NSM example icmp-responder is installed"
else
    echo "NSM example icmp-responder is not installed"
	cd networkservicemesh
	make helm-install-icmp-responder
	make helm-install-vpp-icmp-responder
    make k8s-icmp-check # There are set of checkers that allow to verify both icmp-responder and vpp-icmp-responder examples
	
	echo "" # Add a new-line to output
	make helm-install-vpn
	make k8s-vpn-check
fi
