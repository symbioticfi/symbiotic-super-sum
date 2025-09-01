#!/bin/bash

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "sum-create-task.sh <uint256> <uint256>"
  exit 1
fi

cast send --rpc-url http://127.0.0.1:8545 --json \
 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
 0x99bbA657f2BbC93c02D617f8bA121cB8Fc104Acf \
 "createTask(uint256,uint256)" "$1" "$2"| jq -r '.logs[0].topics[1]'
