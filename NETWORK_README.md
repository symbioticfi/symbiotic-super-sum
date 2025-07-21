# Symbiotic Network Setup

This directory contains a Docker Compose setup for a local Symbiotic blockchain network.

## Quick Start

1. **Generate the network configuration:**
   ```bash
   ./generate_network.sh
   ```

2. **Start the network:**
   ```bash
   cd temp-network && docker compose up -d
   ```

3. **Check status:**
   ```bash
   cd temp-network && docker compose ps
   ```

## Services

### Core Services
- **anvil**: Local Ethereum network (port 8545)
- **deployer**: Contract deployment service
- **genesis-generator**: Network genesis generation service
- **network-validator**: intermediary service to mark network setup completion for all nodes

### Relay Sidecars
- **relay-sidecar-1**: First relay sidecar (port 8081)
- **relay-sidecar-2**: Second relay sidecar (port 8082)
- **relay-sidecar-N**: Nth relay sidecar (port 808N)

### Sum Nodes
- **sum-node-1**: First sum node (port 9091)
- **sum-node-2**: Second sum node (port 9092)
- **sum-node-N**: Nth sum node (port 909N)

## Usage

### Start the network
```bash
cd temp-network && docker compose up -d
```

### Check status
```bash
cd temp-network && docker compose ps
```

### View logs
```bash
# View all logs
cd temp-network && docker compose logs -f

# View specific service logs
cd temp-network && docker compose logs -f anvil
cd temp-network && docker compose logs -f deployer
cd temp-network && docker compose logs -f genesis-generator
cd temp-network && docker compose logs -f relay-sidecar-1
cd temp-network && docker compose logs -f sum-node-1
```

### Stop the network
```bash
cd temp-network && docker compose down
```

### Clean up data
```bash
cd temp-network && docker compose down
rm -rf data-*
```

## Testing

### Create a task
```bash
cast send 0x0E801D84Fa97b50751Dbf25036d067dCf18858bF "createTask(uint256,uint256)" 2 2 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Check task result
```bash
cast call 0x0E801D84Fa97b50751Dbf25036d067dCf18858bF "allTaskResults(uint32)" 0 \
  --rpc-url http://127.0.0.1:8545
```

## Troubleshooting

1. **Services not starting**: Check logs with `cd temp-network && docker compose logs [service-name]`
2. **Port conflicts**: Ensure ports 8545, 8081-8099, 9091-9099 are available
3. **Build issues**: Rebuild with `cd temp-network && docker compose build`
4. **Reset everything**: `cd temp-network && docker compose down -v && rm -rf data-* && docker compose up -d`

## Service Endpoints

- **Anvil RPC**: http://localhost:8545
- **Relay sidecar 1**: http://localhost:8081
- **Relay sidecar 2**: http://localhost:8082
- **Sum node 1**: http://localhost:9091
- **Sum node 2**: http://localhost:9092

## Account Information

All operator accounts are funded with 1 ETH each. The deployer account (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) is used for contract deployment and funding operators.

## Network Configuration

The network supports:
- **Up to 999 operators** (configurable via `generate_network.sh`)
- **Committers**: Operators that commit to the network
- **Aggregators**: Operators that aggregate results
- **Signers**: Regular operators that sign messages

## Development

### Rebuilding Images
```bash
# Rebuild sum-node image
cd temp-network && docker compose build sum-node-1

# Rebuild all images
cd temp-network && docker compose build
```

### Debugging
```bash
# Access container shell
cd temp-network && docker compose exec anvil sh
cd temp-network && docker compose exec relay-sidecar-1 sh
cd temp-network && docker compose exec sum-node-1 sh

# View real-time logs
cd temp-network && docker compose logs -f --tail=100
```

### Performance Monitoring
```bash
# Check resource usage
docker stats

# Monitor specific container
docker stats symbiotic-anvil symbiotic-relay-1 symbiotic-sum-node-1
``` 