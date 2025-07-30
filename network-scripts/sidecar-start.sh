#!/bin/sh
echo "Waiting for driver address..."
until [ -f /deploy-data/driver_address.txt ]; do sleep 2; done
DRIVER_ADDRESS=$(cat /deploy-data/driver_address.txt)
echo "Using driver address: $DRIVER_ADDRESS"

cat > /tmp/sidecar.yaml << EOFCONFIG
driver:
  chain-id: 31337
  address: "$DRIVER_ADDRESS"
log-level: "debug"
log-mode: "pretty"
signer: true
chains:
  - "http://anvil:8545"
bootnodes:
  - /dns4/relay-sidecar-1/tcp/8880/p2p/16Uiu2HAmFUiPYAJ7bE88Q8d7Kznrw5ifrje2e5QFyt7uFPk2G3iR 
http-listen: ":8080"
p2p-listen: "/ip4/0.0.0.0/tcp/8880"
EOFCONFIG

exec /app/relay_sidecar --config /tmp/sidecar.yaml --secret-keys "$1" --storage-dir "$2" $3