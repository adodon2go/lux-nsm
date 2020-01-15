#!/bin/sh

## This script clean-up NSM Example releases inside Minikube

helm delete --purge icmp-responder || true
