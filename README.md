# Sum task network example

## Dependencies
- golang >= v1.25.5
- foundry, installation [guide](https://getfoundry.sh/introduction/installation/)

## Local testing

## Install dependencies

```bash
git submodule update --init --recursive
```

### Build contracts

```bash
forge build
```

### Run local anvil node

```bash
anvil --auto-impersonate --slots-in-an-epoch 1
```

### Deploy contracts

```bash
forge script script/LocalDeploy.s.sol:LocalDeploy --rpc-url http://127.0.0.1:8545 -vv --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Note: By default it will deploy and setup 4 operators and quorum threshold 2/3+1.
If you want to modify check out [script/LocalDeploy.s.sol](./script/LocalDeploy.s.sol)

### Turn on interval mining in anvil

```bash
curl -H "Content-Type: application/json" -X POST --data \
    '{"id":1337,"jsonrpc":"2.0","method":"evm_setIntervalMining","params":[1]}' \
    http://localhost:8545
```

Note: By default anvil is using on-demand mining which is not compatible with relay contracts


### Set network genesis

```bash
./bin/symbiotic_relay_utils network generate-genesis --chains http://127.0.0.1:8545 --driver-address 0x4826533B4897376654Bb4d4AD88B7faFD0C98528 --driver-chainid 31337 --commit --secret-keys 31337:ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Note: if it's failing try again in 5 seconds

### Run relay sidecar nodes

Sidecar 1 (signer only):
```bash
./bin/symbiotic_relay --config sidecar.common.yaml \
    --secret-keys symb/0/15/0xde0b6b3a7640000,evm/1/31337/0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --http-listen :8081 \
    --storage-dir .data-01
```

Sidecar 2 (Signer + Aggregator):
```bash
./bin/symbiotic_relay --config sidecar.common.yaml \
    --secret-keys symb/0/15/0xde0b6b3a7640001,evm/1/31337/0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --http-listen :8082 \
    --storage-dir .data-02 \
    --aggregator true
```

Sidecar 3 (Signer + Committer):
```bash
./bin/symbiotic_relay --config sidecar.common.yaml \
    --secret-keys symb/0/15/0xde0b6b3a7640002,evm/1/31337/0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --http-listen :8083 \
    --storage-dir .data-03 \
    --committer true
```

Note: it's enough to run only 3 out 4 nodes since quorum threshold is 2/3+1

### Build sum node
```bash
cd off-chain
go build -o sum_node ./cmd/node/
```

### Run sum network nodes

Node 1 (connected with sidecar 1):
```bash
./off-chain/sum_node --evm-rpc-url http://127.0.0.1:8545 \
    --relay-api-url http://localhost:8081/api/v1 \
    --contract-address 0x0E801D84Fa97b50751Dbf25036d067dCf18858bF \
    --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Node 2 (connected with sidecar 2):
```bash
./off-chain/sum_node --evm-rpc-url http://127.0.0.1:8545 \
    --relay-api-url http://localhost:8082/api/v1 \
    --contract-address 0x0E801D84Fa97b50751Dbf25036d067dCf18858bF \
    --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Node 3 (connected with sidecar 3):
```bash
./off-chain/sum_node --evm-rpc-url http://127.0.0.1:8545 \
    --relay-api-url http://localhost:8083/api/v1 \
    --contract-address 0x0E801D84Fa97b50751Dbf25036d067dCf18858bF \
    --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Request task

```bash
cast send 0x0E801D84Fa97b50751Dbf25036d067dCf18858bF "createTask(uint256,uint256)" 2 2  --rpc-url http://127.0.0.1:8545 --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Note: it creates task to sum 2+2, in sum and sidecar nodes you can see related logs

### Check task result

```bash
cast call 0x0E801D84Fa97b50751Dbf25036d067dCf18858bF "allTaskResults(uint32)" {TASK_ID} --rpc-url http://127.0.0.1:8545
```

Notes:
- Don't forget to put TASK_ID, it's sequental and starts with 0 
- It prints result in hex, results also might be found in sum node logs