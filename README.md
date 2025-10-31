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
docker compose --project-directory temp-network up -d
```

3. **Check status:**

```bash
docker compose --project-directory temp-network ps
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
docker compose --project-directory temp-network up -d
```

### Check status

```bash
docker compose --project-directory temp-network ps
```

### View logs

```bash
# View all logs
docker compose --project-directory temp-network logs -f

# View specific service logs
docker compose --project-directory temp-network logs -f anvil
docker compose --project-directory temp-network logs -f anvil-settlement
docker compose --project-directory temp-network logs -f deployer
docker compose --project-directory temp-network logs -f genesis-generator
docker compose --project-directory temp-network logs -f relay-sidecar-1
docker compose --project-directory temp-network logs -f sum-node-1
```

### Stop the network

```bash
docker compose --project-directory temp-network down
```

### Clean up data

```bash
docker compose --project-directory temp-network down -v
rm -rf temp-network
```

### Create a task

```bash
taskID=$(cast send --rpc-url http://127.0.0.1:8545 --json \
 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
 0xDf12251aD82BF1eb0E0951AD15d37AE5ED3Ac1dF \
 "createTask(uint256,uint256)" 33 9 | jq -r '.logs[0].topics[1]')
```

or

```bash
taskID=$(cast send --rpc-url http://127.0.0.1:8546 --json \
 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
 0xDf12251aD82BF1eb0E0951AD15d37AE5ED3Ac1dF \
 "createTask(uint256,uint256)" 33 9 | jq -r '.logs[0].topics[1]')
```

### Check task result

```bash
result=$(cast call --rpc-url http://127.0.0.1:8545 \
 0xDf12251aD82BF1eb0E0951AD15d37AE5ED3Ac1dF \
 "responses(bytes32)" $taskID)
cast decode-abi --json "data()(uint48,uint256)" $result
```

or

```bash
result=$(cast call --rpc-url http://127.0.0.1:8546 \
 0xDf12251aD82BF1eb0E0951AD15d37AE5ED3Ac1dF \
 "responses(bytes32)" $taskID)
cast decode-abi --json "data()(uint48,uint256)" $result
```

### Troubleshooting

1. **Services not starting**: Check logs with `docker compose --project-directory temp-network logs [service-name]`
2. **Port conflicts**: Ensure ports 8545-8546 8081-8099, 9091-9099 are available
3. **Build issues**: Rebuild with `docker compose --project-directory temp-network build`
4. **Reset everything**: `docker compose --project-directory temp-network down -v && rm -rf temp-network && ./generate_network.sh && docker compose --project-directory temp-network up -d`

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
docker compose --project-directory temp-network exec anvil sh
docker compose --project-directory temp-network exec relay-sidecar-1 sh
docker compose --project-directory temp-network exec sum-node-1 sh

# View real-time logs
docker compose --project-directory temp-network logs -f --tail=100
```

### Performance Monitoring

```bash
# Check resource usage
docker stats

# Monitor specific container
docker stats symbiotic-anvil symbiotic-relay-1 symbiotic-sum-node-1
```

## Local Deployments

http://anvil:8545:

- `ValSetDriver`: 0x43C27243F96591892976FFf886511807B65a33d5
- `SumTask`: 0xDf12251aD82BF1eb0E0951AD15d37AE5ED3Ac1dF
- `VotingPowerProvider`: 0x369c72C823A4Fc8d2A3A5C3B15082fb34A342878
- `KeyRegistry`: 0xe1557A820E1f50dC962c3392b875Fe0449eb184F
- `Settlement`: 0x882B9439598239d9626164f7578F812Ef324F5Cb
- `Network`: 0xfdc4b2cA12dD7b1463CC01D8022a49BDcf5cFa24

http://anvil-settlement:8546:

- `SumTask`: 0xDf12251aD82BF1eb0E0951AD15d37AE5ED3Ac1dF
- `Settlement`: 0x882B9439598239d9626164f7578F812Ef324F5Cb
