#!/bin/sh

## This script clean-up NSM release inside Kind

cd networkservicemesh
make helm-delete-nsm
