#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "sum-result.sh <bytes32>"
  exit 1
fi

result=$(cast call --rpc-url http://127.0.0.1:8545 \
 0x99bbA657f2BbC93c02D617f8bA121cB8Fc104Acf \
 "responses(bytes32)" "$1")
cast decode-abi --json "data()(uint48,uint256)" $result | jq -r .[1] 
