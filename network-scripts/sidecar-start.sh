#!/bin/sh

DRIVER_ADDRESS=0x43C27243F96591892976FFf886511807B65a33d5

cat > /tmp/sidecar.yaml << EOFCONFIG
# Logging
log:
  level: "debug"
  mode: "pretty"

# API Server Configuration
api:
  listen: ":8080"

# Metrics Configuration
metrics:
  pprof: true

# Driver Contract
driver:
  chain-id: 31337
  address: "$DRIVER_ADDRESS"

# P2P Configuration
p2p:
  listen: "/ip4/0.0.0.0/tcp/8880"
  bootnodes:
    - /dns4/relay-sidecar-1/tcp/8880/p2p/16Uiu2HAmFUiPYAJ7bE88Q8d7Kznrw5ifrje2e5QFyt7uFPk2G3iR
  dht-mode: "server"
  mdns: true

# EVM Configuration
evm:
  chains:
    - "http://anvil:8545"
    - "http://anvil-settlement:8546"
  max-calls: 30
EOFCONFIG


exec /app/relay_sidecar --config /tmp/sidecar.yaml --secret-keys "$1" --storage-dir "$2"
