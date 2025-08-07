# Sum task network example

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/symbioticfi/symbiotic-super-sum)

## Prerequisites

### Clone the repository

```bash
git clone https://github.com/symbioticfi/symbiotic-super-sum.git
```

### Install submodules

Install Git LFS

- macOS:

  ```bash
  brew install git-lfs
  git lfs install
  ```

- Debian/Ubuntu:

  ```bash
  sudo apt update && sudo apt install git-lfs
  git lfs install
  ```

Update submodules

```bash
git submodule update --init --recursive
```

## Running in docker

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
cast send 0x4826533B4897376654Bb4d4AD88B7faFD0C98528 "createTask(uint256,uint256)" 2 2 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Check task result

```bash
cast call 0x4826533B4897376654Bb4d4AD88B7faFD0C98528 "responses(bytes32)" 0x556b8b8eec9bc205e200fe8109800d09f66774f659322c71f9df42f668d18416 \
  --rpc-url http://127.0.0.1:8545
```

or

```bash
cast call 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "responses(bytes32)" 0x556b8b8eec9bc205e200fe8109800d09f66774f659322c71f9df42f668d18416 \
  --rpc-url http://127.0.0.1:8546
```

### Troubleshooting

1. **Services not starting**: Check logs with `cd temp-network && docker compose logs [service-name]`
2. **Port conflicts**: Ensure ports 8545-8546 8081-8099, 9091-9099 are available
3. **Build issues**: Rebuild with `cd temp-network && docker compose build && cd ..`
4. **Reset everything**: `cd temp-network && docker compose down -v && rm -rf data-* && docker compose up -d && cd ..`

### Service Endpoints

- **Anvil RPC**: http://localhost:8545
- **Anvil Settlement RPC**: http://localhost:8545
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

## Running on host machine

### Dependencies

- golang >= v1.25.5
- foundry, installation [guide](https://getfoundry.sh/introduction/installation/)

### Build contracts

```bash
forge build
```

### Run local anvil nodes

**Run first node:**

```bash
anvil --port 8545 --chain-id 31337 --timestamp 1754051800 --auto-impersonate --slots-in-an-epoch 1
```

**Run second node:**

```bash
anvil --port 8546 --chain-id 31338 --timestamp 1754051800 --auto-impersonate --slots-in-an-epoch 1
```

### Deploy contracts

**Deploy full local setup with Settlement and SumTask on 2 chains:**

```bash
mkdir -p "temp-network/deploy-data"
forge script script/LocalDeploy.s.sol:LocalDeploy --rpc-url http://127.0.0.1:8545 -vv --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/SettlementChainDeploy.s.sol:SettlementChainDeploy --rpc-url http://127.0.0.1:8546 -vv --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/ValSetDriverDeploy.s.sol:ValSetDriverDeploy --rpc-url http://127.0.0.1:8545 -vv --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Note: By default it will deploy and setup 4 operators and quorum threshold 2/3+1.
If you want to modify check out [script/LocalDeploy.s.sol](./script/LocalDeploy.s.sol)

### Turn on interval mining in anvil

```bash
cast rpc --rpc-url http://127.0.0.1:8545 evm_setIntervalMining 1
cast rpc --rpc-url http://127.0.0.1:8546 evm_setIntervalMining 1
```

Note: By default anvil is using on-demand mining which is not compatible with relay contracts

### Set network genesis

```bash
./bin/symbiotic_relay_utils network \
    --chains http://127.0.0.1:8545,http://127.0.0.1:8546 \
    --driver-address 0x1291Be112d480055DaFd8a610b7d1e203891C274 \
    --driver-chainid 31337 \
  generate-genesis \
    --commit \
    --secret-keys 31337:ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,31338:ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Note: If it's failing try again in 5 seconds

### Run relay sidecar nodes

Sidecar 1 (signer only):

```bash
./bin/symbiotic_relay --config sidecar.common.yaml \
    --secret-keys symb/0/15/0xde0b6b3a7640000,evm/1/31337/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640000,evm/1/31338/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640000,p2p/1/0/0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140,p2p/1/1/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640000 \
    --http-listen :8081 \
    --p2p-listen "/ip4/127.0.0.1/tcp/8881" \
    --storage-dir .data-01
```

Sidecar 2 (Signer + Aggregator):

```bash
./bin/symbiotic_relay --config sidecar.common.yaml \
    --secret-keys symb/0/15/0xde0b6b3a7640001,evm/1/31337/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640001,evm/1/31338/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640001,p2p/1/0/0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140,p2p/1/1/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640001 \
    --http-listen :8082 \
    --p2p-listen "/ip4/127.0.0.1/tcp/8882" \
    --storage-dir .data-02 \
    --aggregator true
```

Sidecar 3 (Signer + Committer):

```bash
./bin/symbiotic_relay --config sidecar.common.yaml \
    --secret-keys symb/0/15/0xde0b6b3a7640002,evm/1/31337/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640002,evm/1/31338/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640002,p2p/1/0/0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140,p2p/1/1/0x0000000000000000000000000000000000000000000000000DE0B6B3A7640002 \
    --http-listen :8083 \
    --p2p-listen "/ip4/127.0.0.1/tcp/8883" \
    --storage-dir .data-03 \
    --committer true
```

Note: It's enough to run only 3 out 4 nodes since quorum threshold is 2/3+1

### Build sum node

```bash
cd off-chain
go build -o sum_node ./cmd/node/
cd ..
```

### Run sum network nodes

Node 1 (connected with sidecar 1):

```bash
./off-chain/sum_node --evm-rpc-urls http://127.0.0.1:8545,http://127.0.0.1:8546 \
    --relay-api-url 127.0.0.1:8081 \
    --contract-addresses 0x4826533B4897376654Bb4d4AD88B7faFD0C98528,0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 \
    --private-key 0000000000000000000000000000000000000000000000000DE0B6B3A7640000
```

Node 2 (connected with sidecar 2):

```bash
./off-chain/sum_node --evm-rpc-urls http://127.0.0.1:8545,http://127.0.0.1:8546 \
    --relay-api-url 127.0.0.1:8082 \
    --contract-addresses 0x4826533B4897376654Bb4d4AD88B7faFD0C98528,0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 \
    --private-key 0000000000000000000000000000000000000000000000000DE0B6B3A7640001
```

Node 3 (connected with sidecar 3):

```bash
./off-chain/sum_node --evm-rpc-urls http://127.0.0.1:8545,http://127.0.0.1:8546 \
    --relay-api-url 127.0.0.1:8083 \
    --contract-addresses 0x4826533B4897376654Bb4d4AD88B7faFD0C98528,0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 \
    --private-key 0000000000000000000000000000000000000000000000000DE0B6B3A7640002
```

### Request task

```bash
cast send 0x4826533B4897376654Bb4d4AD88B7faFD0C98528 "createTask(uint256,uint256)" 2 2  --rpc-url http://127.0.0.1:8545 --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

or

```bash
cast send 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "createTask(uint256,uint256)" 2 2  --rpc-url http://127.0.0.1:8546 --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Note: It creates task to sum 2+2, in sum and sidecar nodes you can see related logs

### Check task result

Don't forget to replace `{TASK_ID}`, you can find it in sum node's logs

```bash
cast call 0x4826533B4897376654Bb4d4AD88B7faFD0C98528 "responses(bytes32)" {TASK_ID} --rpc-url http://127.0.0.1:8545
```

or

```bash
cast call 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "responses(bytes32)" {TASK_ID} --rpc-url http://127.0.0.1:8546
```

Note: It prints result in hex, results also might be found in sum node logs
