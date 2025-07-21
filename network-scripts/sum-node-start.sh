#!/bin/sh
echo "Waiting for SumTask contract address..."
until [ -f /deploy-data/sumtask_address.txt ]; do sleep 2; done
SUMTASK_ADDRESS=$(cat /deploy-data/sumtask_address.txt)
echo "Using SumTask address: $SUMTASK_ADDRESS"

exec /app/sum-node --evm-rpc-url http://anvil:8545 --relay-api-url "$1" --contract-address "$SUMTASK_ADDRESS" --private-key "$2" --log-level info 