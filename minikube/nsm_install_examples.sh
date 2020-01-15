#!/bin/sh

## This script installs NSM Examples inside Minikube: icmp-responder, vpn, vpp-icmp-responder

# Check if NSM is installed
kubectl get pods -A | grep nsm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NSM is installed"
else
    echo "NSM is not installed"
    sh nsm_install.sh
fi

# Check if NSM example icmp-responder is installed
kubectl get pods -A | grep icmp-responder > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "NSM example icmp-responder is installed"
else
    echo "NSM example icmp-responder is not installed"
    cp icmp-responder-nse_patch.diff networkservicemesh/
    cd networkservicemesh && git apply icmp-responder-nse_patch.diff
    make helm-install-icmp-responder
    
    # we need to check that all NSC & NSE from example are up & running
	# TODO: automatize this
    SLEEP=30
    echo "waiting $SLEEP sec for all NSC & NSE from example to become up & running"
    sleep $SLEEP
    
    # helm template installed icmp-responder example in nsm-system namespace
    curl -s https://raw.githubusercontent.com/networkservicemesh/networkservicemesh/master/scripts/nsc_ping_all.sh | sed 's/{NSM_NAMESPACE:-default}/{NSM_NAMESPACE:-nsm-system}/g' | bash
fi
