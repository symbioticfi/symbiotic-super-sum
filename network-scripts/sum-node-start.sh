#!/bin/sh
SUMTASK_ADDRESS=0xDf12251aD82BF1eb0E0951AD15d37AE5ED3Ac1dF
SETTLEMENT_SUMTASK_ADDRESS=0xDf12251aD82BF1eb0E0951AD15d37AE5ED3Ac1dF

exec /app/sum-node --evm-rpc-urls http://anvil:8545,http://anvil-settlement:8546 --relay-api-url "$1" --contract-addresses "$SUMTASK_ADDRESS,$SETTLEMENT_SUMTASK_ADDRESS" --private-key "$2" --log-level info
