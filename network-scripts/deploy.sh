#!/bin/sh
set -e

echo "Waiting for anvil to be ready..."
until cast client --rpc-url http://anvil:8545 > /dev/null 2>&1; do sleep 1; done

echo "Deploying contracts..."
forge script script/LocalDeploy.s.sol:LocalDeploy --rpc-url http://anvil:8545 -vv --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 | tee /deploy-data/deployment.log

# Extract contract addresses and save to shared files
DRIVER_ADDRESS=$(grep "Driver:" /deploy-data/deployment.log | awk '{print $2}')
SUMTASK_ADDRESS=$(grep "SumTask contract:" /deploy-data/deployment.log | awk '{print $3}')
echo "$DRIVER_ADDRESS" > /deploy-data/driver_address.txt
echo "$SUMTASK_ADDRESS" > /deploy-data/sumtask_address.txt
echo "Driver address saved: $DRIVER_ADDRESS"
echo "SumTask address saved: $SUMTASK_ADDRESS"

echo "Funding all operator accounts..."
for i in $(seq 0 $((OPERATOR_COUNT - 1))); do
  seed="operator_$i"
  private_key=$(echo -n "$seed" | sha256sum | cut -d' ' -f1)
  address=$(cast wallet address --private-key $private_key)
  echo "Funding operator $i: $address"
  cast send --value 1ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 $address --rpc-url http://anvil:8545
done

echo "Setting interval mining..."
cast rpc --rpc-url http://anvil:8545 evm_setIntervalMining 1

echo "Deployment completed successfully!"

# Create deployment completion marker
echo "$(date): Deployment completed successfully" > /deploy-data/deployment-complete.marker
echo "Deployment completion marker created" 