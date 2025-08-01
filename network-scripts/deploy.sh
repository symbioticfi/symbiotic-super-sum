#!/bin/sh
set -e

echo "Waiting for anvil to be ready..."
until cast client --rpc-url http://anvil:8545 > /dev/null 2>&1; do sleep 1; done
until cast client --rpc-url http://anvil-settlement:8546 > /dev/null 2>&1; do sleep 1; done

echo "Deploying contracts..."
forge script script/LocalDeploy.s.sol:LocalDeploy --rpc-url http://anvil:8545 -vv --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 | tee /deploy-data/deployment.log
forge script script/SettlementChainDeploy.s.sol:SettlementChainDeploy --rpc-url http://anvil-settlement:8546 -vv --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 | tee /deploy-data/settlement-deployment.log

echo 'Waiting for relay contracts file...'
until [ -f /deploy-data/relay_contracts.json ]; do sleep 2; done

DRIVER_ADDRESS=$(jq -r '.driver.addr' /deploy-data/relay_contracts.json)
echo "Driver address from relay_contracts.json: $DRIVER_ADDRESS"
SECONDARY_SETTLEMENT_ADDRESS=$(jq -r '.settlements[1].addr' /deploy-data/relay_contracts.json)
echo "Settlement SumTask address from relay_contracts.json: $SECONDARY_SETTLEMENT_ADDRESS"

cast send $DRIVER_ADDRESS "addReplica((uint64,address))" "(31338,$SECONDARY_SETTLEMENT_ADDRESS)" --rpc-url http://anvil:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 | tee /deploy-data/add-replica.log

echo "Setting interval mining..."
cast rpc --rpc-url http://anvil:8545 evm_setIntervalMining 1
cast rpc --rpc-url http://anvil-settlement:8546 evm_setIntervalMining 1

echo "Jumping ahead of time (+120 seconds)"
cast rpc --rpc-url http://anvil:8545 evm_increaseTime 120
cast rpc --rpc-url http://anvil-settlement:8546 evm_increaseTime 120

echo "Deployment completed successfully!"

# Create deployment completion marker
echo "$(date): Deployment completed successfully" > /deploy-data/deployment-complete.marker
echo "Deployment completion marker created" 