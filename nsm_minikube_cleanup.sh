#!/bin/sh

## This script clean-up NSM release inside Minikube

helm delete --purge nsm || true
