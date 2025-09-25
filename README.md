# Sum task network example

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/symbioticfi/symbiotic-super-sum)

## Prerequisites

### Clone the repository

```bash
git clone https://github.com/symbioticfi/symbiotic-super-sum.git
```

Update submodules

```bash
git submodule update --init --recursive
```

Install dependencies

```bash
npm install
```

## Running in Docker

### Dependencies

- Docker

### Quick Start

1. **Generate the network configuration:**

   ```bash
   ./generate_network.sh
   ```

2. **Start the network:**

   ```bash
   cd temp-network && docker compose up -d && cd ..
   ```

3. **Check status:**
   ```bash
   cd temp-network && docker compose ps && cd ..
   ```

### Services

#### Core Services

- **anvil**: Local Ethereum network (port 8545)
- **anvil-settlement**: Local Ethereum network (port 8546)
- **deployer**: Contract deployment service
- **genesis-generator**: Network genesis generation service
- **network-validator**: intermediary service to mark network setup completion for all nodes

#### Relay Sidecars

- **relay-sidecar-1**: First relay sidecar (port 8081)
- **relay-sidecar-2**: Second relay sidecar (port 8082)
- **relay-sidecar-N**: Nth relay sidecar (port 808N)

#### Sum Nodes

- **sum-node-1**: First sum node (port 9091)
- **sum-node-2**: Second sum node (port 9092)
- **sum-node-N**: Nth sum node (port 909N)

### Start the network

```bash
cd temp-network && docker compose up -d && cd ..
```

### Check status

```bash
cd temp-network && docker compose ps && cd ..
```

### View logs

```bash
# View all logs
cd temp-network && docker compose logs -f

# View specific service logs
cd temp-network && docker compose logs -f anvil
cd temp-network && docker compose logs -f anvil-settlement
cd temp-network && docker compose logs -f deployer && cd ..
cd temp-network && docker compose logs -f genesis-generator && cd ..
cd temp-network && docker compose logs -f relay-sidecar-1
cd temp-network && docker compose logs -f sum-node-1
```

### Stop the network

```bash
cd temp-network && docker compose down && cd ..
```

### Clean up data

```bash
cd temp-network && docker compose down
rm -rf data-* && cd ..
```

### Create a task

```bash
cast send 0x5a96fCeD765c5d7ae00Fc4d0A5Bd7d86992E8123 "createTask(uint256,uint256)" 2 2 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Check task result

Don't forget to replace `{TASK_ID}`, you can find it in sum node's logs (e.g., `0x556b8b8eec9bc205e200fe8109800d09f66774f659322c71f9df42f668d18416`)

```bash
cast call 0x5a96fCeD765c5d7ae00Fc4d0A5Bd7d86992E8123 "responses(bytes32)" {TASK_ID} \
  --rpc-url http://127.0.0.1:8545
```

or

```bash
cast call 0x5a96fCeD765c5d7ae00Fc4d0A5Bd7d86992E8123 "responses(bytes32)" {TASK_ID} \
  --rpc-url http://127.0.0.1:8546
```

### Troubleshooting

1. **Services not starting**: Check logs with `cd temp-network && docker compose logs [service-name]`
2. **Port conflicts**: Ensure ports 8545-8546 8081-8099, 9091-9099 are available
3. **Build issues**: Rebuild with `cd temp-network && docker compose build && cd ..`
4. **Reset everything**: `cd temp-network && docker compose down -v && rm -rf data-* && docker compose up -d && cd ..`

### Service Endpoints

- **Anvil RPC**: http://localhost:8545
- **Anvil Settlement RPC**: http://localhost:8546
- **Relay sidecar 1**: http://localhost:8081
- **Relay sidecar 2**: http://localhost:8082
- **Sum node 1**: http://localhost:9091
- **Sum node 2**: http://localhost:9092

### Network Configuration

The network supports:

- **Up to 999 operators** (configurable via `generate_network.sh`)
- **Committers**: Operators that commit to the network
- **Aggregators**: Operators that aggregate results
- **Signers**: Regular operators that sign messages

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

## Local Deployments

- `SumTask`: 0x5a96fCeD765c5d7ae00Fc4d0A5Bd7d86992E8123
- `Network`: 0xF15f90Fd25d565dD9dEF6eca6997366D198da0Fd
- `VotingPowerProvider`: 0xA537F4e6C541a3CF0e0FEA9C05599e559f3cca67
- `KeyRegistry`: 0xf417E48Fc77dd289CDFbC8df23df0f664C4850bd
- `ValSetDriver`: 0x99452A3583B47cD706622d64cD57c353Ac55ae77
- `Settlements`: 0xEfA6DDa36a3A85d9Da7220B964FE4F2d959aD582
