#!/bin/sh

## This script cleans up vl3 single domain hello example (from https://github.com/tiswanso/examples/tree/joycej_vl3/examples/vl3_basic)

if [ -z "$KUBECONFIG1" ]; then
  echo "$KUBECONFIG1 env variable is undefined"
  exit 1
fi

examples/examples/vl3_basic/scripts/demo_vl3_single.sh --kconf_clus1=$KUBECONFIG1 --hello --nowait --delete


