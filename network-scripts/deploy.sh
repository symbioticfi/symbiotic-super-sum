#!/bin/sh
set -e

ANVIL_RPC_URL=${ANVIL_RPC_URL:-http://anvil:8545}
SETTLEMENT_RPC_URL=${SETTLEMENT_RPC_URL:-http://anvil-settlement:8546}
DEPLOY_CONFIG_PATH=${DEPLOY_CONFIG_PATH:-/my-relay-deploy.toml}

echo "Waiting for anvil to be ready..."
until cast client --rpc-url "$ANVIL_RPC_URL" > /dev/null 2>&1; do sleep 1; done
until cast client --rpc-url "$SETTLEMENT_RPC_URL" > /dev/null 2>&1; do sleep 1; done

echo "Deploying contracts..."
if [ ! -f "$DEPLOY_CONFIG_PATH" ]; then
    echo "Deployment config not found at '$DEPLOY_CONFIG_PATH'" >&2
    exit 1
fi
./lib/relay-contracts-new/script/deploy/relay-deploy.sh ./script/MyRelayDeploy.sol "$DEPLOY_CONFIG_PATH" --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

echo 'Waiting for deployment completion...'
until [ -f /deploy-data/deployment-completed.json ]; do sleep 2; done

echo "Setting interval mining..."
cast rpc --rpc-url "$ANVIL_RPC_URL" evm_setIntervalMining 1
cast rpc --rpc-url "$SETTLEMENT_RPC_URL" evm_setIntervalMining 1

echo "Mine a single block to finalize the deployment..."
cast rpc --rpc-url "$ANVIL_RPC_URL" evm_mine
cast rpc --rpc-url "$SETTLEMENT_RPC_URL" evm_mine

echo "Deployment completed successfully!"

# Create deployment completion marker
echo "$(date): Deployment completed successfully" > /deploy-data/deployment-complete.marker
echo "Deployment completion marker created" 
