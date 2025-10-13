#!/bin/sh
set -e

# Run the deployment script
./lib/relay-contracts-new/script/deploy/deploy.sh --config network-scripts/deploy-config.yaml --script script/DeployAll.s.sol --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast