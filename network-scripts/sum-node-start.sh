#!/bin/sh
echo "Waiting for sum_task_contracts.json file..."
until [ -f /deploy-data/sum_task_contracts.json ]; do sleep 2; done

SUMTASK_ADDRESS=$(jq -r '.sumTasks[0].addr' /deploy-data/sum_task_contracts.json)
echo "SumTask address from sum_task_contracts.json: $SUMTASK_ADDRESS"
SETTLEMENT_SUMTASK_ADDRESS=$(jq -r '.sumTasks[1].addr' /deploy-data/sum_task_contracts.json)
echo "Settlement SumTask address from sum_task_contracts.json: $SETTLEMENT_SUMTASK_ADDRESS"

exec /app/sum-node --evm-rpc-urls http://anvil:8545,http://anvil-settlement:8546 --relay-api-url "$1" --contract-addresses "$SUMTASK_ADDRESS,$SETTLEMENT_SUMTASK_ADDRESS" --private-key "$2" --log-level info 