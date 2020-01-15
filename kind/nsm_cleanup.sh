#!/bin/sh

## This script clean-up NSM release inside Kind

cd networkservicemesh
make make helm-delete-nsm
