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
EOFCONFIG

exec /app/relay_sidecar --config /tmp/sidecar.yaml --secret-keys "$1" --http-listen "$2" --storage-dir "$3" $4 