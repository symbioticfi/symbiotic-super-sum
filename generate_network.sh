#!/bin/bash

# Symbiotic Network Generator
# This script generates a Docker Compose setup for a local blockchain network
# with configurable number of operators, commiters, and aggregators

set -e

# Define the image tag for the relay service, that the current sum node is compatible with
RELAY_IMAGE_TAG="0.2.1-20250802065445-3f8139849d3f"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
DEFAULT_OPERATORS=4
DEFAULT_COMMITERS=1
DEFAULT_AGGREGATORS=1
MAX_OPERATORS=999


print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}


validate_number() {
    local num=$1
    local name=$2
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ]; then
        print_error "$name must be a positive integer"
        exit 1
    fi
}

get_user_input() {
    echo
    print_header "Symbiotic Network Configuration"
    echo
    
    read -p "Enter number of operators (default: $DEFAULT_OPERATORS, max: $MAX_OPERATORS): " operators
    operators=${operators:-$DEFAULT_OPERATORS}
    validate_number "$operators" "Number of operators"
    
    read -p "Enter number of commiters (default: $DEFAULT_COMMITERS): " commiters
    commiters=${commiters:-$DEFAULT_COMMITERS}
    validate_number "$commiters" "Number of commiters"
    
    read -p "Enter number of aggregators (default: $DEFAULT_AGGREGATORS): " aggregators
    aggregators=${aggregators:-$DEFAULT_AGGREGATORS}
    validate_number "$aggregators" "Number of aggregators"
    
    # Validate that commiters + aggregators <= operators
    total_special_roles=$((commiters + aggregators))
    if [ "$total_special_roles" -gt "$operators" ]; then
        print_error "Total commiters ($commiters) + aggregators ($aggregators) cannot exceed total operators ($operators)"
        exit 1
    fi
    
    if [ "$operators" -gt $MAX_OPERATORS ]; then
        print_error "Maximum $MAX_OPERATORS operators supported. Requested: $operators"
        exit 1
    fi
    
    print_status "Configuration:"
    print_status "  Operators: $operators"
    print_status "  Committers: $commiters"
    print_status "  Aggregators: $aggregators"
    print_status "  Regular signers: $((operators - total_special_roles))"
}

# Function to generate Docker Compose file
generate_docker_compose() {
    local operators=$1
    local commiters=$2
    local aggregators=$3
    
    local network_dir="temp-network"
    
    if [ -d "$network_dir" ]; then
        print_status "Cleaning up existing $network_dir directory..."
        rm -rf "$network_dir"
    fi
    
    mkdir -p "$network_dir/deploy-data"
    
    for i in $(seq 1 $operators); do
        local storage_dir="$network_dir/data-$(printf "%02d" $i)"
        mkdir -p "$storage_dir"
        # Make sure the directory is writable
        chmod 777 "$storage_dir"
    done

    local anvil_port=8545
    local anvil_settlement_port=8546
    local relay_start_port=8081
    local sum_start_port=9091
    
    cat > "$network_dir/docker-compose.yml" << EOF
services:
  # Main Anvil local Ethereum network (Chain ID: 31337)
  anvil:
    image: ghcr.io/foundry-rs/foundry:v1.2.3
    container_name: symbiotic-anvil
    entrypoint: ["anvil"]
    command: "--port 8545 --chain-id 31337 --timestamp 1754051800 --auto-impersonate --slots-in-an-epoch 1 --accounts 10 --balance 10000 --gas-limit 30000000"
    environment:
      - ANVIL_IP_ADDR=0.0.0.0
    ports:
      - "8545:8545"
    networks:
      - symbiotic-network
    healthcheck:
      test: ["CMD", "cast", "client", "--rpc-url", "http://localhost:8545"]
      interval: 2s
      timeout: 1s
      retries: 10

  # Settlement Anvil local Ethereum network (Chain ID: 31338)
  anvil-settlement:
    image: ghcr.io/foundry-rs/foundry:v1.2.3
    container_name: symbiotic-anvil-settlement
    entrypoint: ["anvil"]
    command: "--port 8546 --chain-id 31338 --timestamp 1754051800 --auto-impersonate --slots-in-an-epoch 1 --accounts 10 --balance 10000 --gas-limit 30000000"
    environment:
      - ANVIL_IP_ADDR=0.0.0.0
    ports:
      - "8546:8546"
    networks:
      - symbiotic-network
    healthcheck:
      test: ["CMD", "cast", "client", "--rpc-url", "http://localhost:8546"]
      interval: 2s
      timeout: 1s
      retries: 10

  # Contract deployment service for main chain
  deployer:
    image: ghcr.io/foundry-rs/foundry:v1.3.0
    container_name: symbiotic-deployer
    volumes:
      - ../:/app
      - ../cache:/app/cache
      - ../broadcast:/app/broadcast
      - ./deploy-data:/deploy-data
    working_dir: /app
    command: ./network-scripts/deploy.sh
    depends_on:
      anvil:
        condition: service_healthy
      anvil-settlement:
        condition: service_healthy
    networks:
      - symbiotic-network
    environment:
      - OPERATOR_COUNT=$operators

  # Genesis generation service
  genesis-generator:
    image: symbioticfi/relay:latest
    container_name: symbiotic-genesis-generator
    volumes:
      - ../:/workspace
      - ./deploy-data:/deploy-data
    working_dir: /workspace
    command: ./network-scripts/genesis-generator.sh
    depends_on:
      deployer:
        condition: service_completed_successfully
    networks:
      - symbiotic-network

EOF

    local committer_count=0
    local aggregator_count=0
    local signer_count=0
    
    # Calculate symb private key properly
    # ECDSA secp256k1 private keys must be 32 bytes (64 hex chars) and within range [1, n-1]
    # where n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
    BASE_PRIVATE_KEY=1000000000000000000
    SWARM_KEY=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140

    for i in $(seq 1 $operators); do
        local port=$((relay_start_port + i - 1))
        local storage_dir="data-$(printf "%02d" $i)"
        local key_index=$((i - 1))
        
        # Determine role for this operator
        local role_flags=""
        local role_name="signer"
        
        if [ $committer_count -lt $commiters ]; then
            role_flags="--committer true"
            role_name="committer"
            committer_count=$((committer_count + 1))
        elif [ $aggregator_count -lt $aggregators ]; then
            role_flags="--aggregator true"
            role_name="aggregator"
            aggregator_count=$((aggregator_count + 1))
        else
            role_flags="--signer true"
            signer_count=$((signer_count + 1))
        fi
        
        SYMB_PRIVATE_KEY_DECIMAL=$(($BASE_PRIVATE_KEY + $key_index))
        SYMB_PRIVATE_KEY_HEX=$(printf "%064x" $SYMB_PRIVATE_KEY_DECIMAL)
        
        # Validate ECDSA secp256k1 private key range (must be between 1 and n-1)
        # Maximum valid key: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140
        if [ $SYMB_PRIVATE_KEY_DECIMAL -eq 0 ]; then
            echo "ERROR: Generated private key is zero (invalid for ECDSA)"
            exit 1
        fi
        
        cat >> "$network_dir/docker-compose.yml" << EOF

  # Relay sidecar $i ($role_name)
  relay-sidecar-$i:
    image: symbioticfi/relay:$RELAY_IMAGE_TAG
    container_name: symbiotic-relay-$i
    command:
      - /workspace/network-scripts/sidecar-start.sh 
      - symb/0/15/0x$SYMB_PRIVATE_KEY_HEX,evm/1/31337/0x$SYMB_PRIVATE_KEY_HEX,evm/1/31338/0x$SYMB_PRIVATE_KEY_HEX,p2p/1/0/$SWARM_KEY,p2p/1/1/$SYMB_PRIVATE_KEY_HEX
      - /app/$storage_dir
      - $role_flags
    ports:
      - "$port:8080"
    volumes:
      - ../:/workspace
      - ./$storage_dir:/app/$storage_dir
      - ./deploy-data:/deploy-data
    depends_on:
      genesis-generator:
        condition: service_completed_successfully
    networks:
      - symbiotic-network
    restart: unless-stopped

EOF

        local relay_port=$((relay_start_port + i - 1))
        local sum_port=$((sum_start_port + i - 1))
        
        cat >> "$network_dir/docker-compose.yml" << EOF

  # Sum node $i
  sum-node-$i:
    build:
      context: ../off-chain
      dockerfile: Dockerfile
    container_name: symbiotic-sum-node-$i
    entrypoint: ["/workspace/network-scripts/sum-node-start.sh"]
    command: ["relay-sidecar-$i:8080", "$SYMB_PRIVATE_KEY_HEX"]
    volumes:
      - ../:/workspace
      - ./deploy-data:/deploy-data
    ports:
      - "$sum_port:8080"
    depends_on:
      relay-sidecar-$i:
        condition: service_started
    networks:
      - symbiotic-network
    restart: unless-stopped

EOF
    done
    
    cat >> "$network_dir/docker-compose.yml" << EOF

networks:
  symbiotic-network:
    driver: bridge

EOF
}


# Main execution
main() {
    print_header "Symbiotic Network Generator"
    
    # Check if required tools are available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    get_user_input
    

    print_status "Generating Docker Compose configuration..."
    print_status "Creating $operators new operator accounts..."
    generate_docker_compose "$operators" "$commiters" "$aggregators"
    
    print_header "Setup Complete!"
    echo
    print_status "Files generated in temp-network/ directory:"
    echo "  - temp-network/docker-compose.yml"
    echo "  - temp-network/data-* (storage directories)"
    echo
    print_status "To start the network, run:"
    echo "  cd temp-network && docker compose up -d && cd .."
    echo
    print_status "To check the status, run:"
    echo "  cd temp-network && docker compose ps && cd .."
    echo
    print_status "To view logs, run:"
    echo "  cd temp-network && docker compose logs -f"
    echo
    print_warning "Note: The first startup may take several minutes(2-4mins) as it needs to:"
    echo "  1. Download Docker images"
    echo "  2. Build the sum-node image"
    echo "  3. Deploy contracts"
    echo "  4. Generate network genesis and fund operators"
    echo
}

main "$@" 