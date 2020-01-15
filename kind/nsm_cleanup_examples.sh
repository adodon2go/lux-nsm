#!/bin/sh

## This script clean-up NSM Example releases inside Kind

cd networkservicemesh

make helm-delete-icmp-responder
make helm-delete-vpp-icmp-responder
make helm-delete-vpn
