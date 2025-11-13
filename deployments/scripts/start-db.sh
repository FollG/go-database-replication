#!/bin/bash

set -e

echo "🚀 Starting MySQL Cluster..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Navigate to deployments directory
cd "$(dirname "$0")/.."

# Start database cluster
log_info "Starting MySQL cluster..."
docker-compose -f db.docker-compose.yml up -d

# Wait for MySQL to be ready
log_info "Waiting for MySQL containers to be ready..."
sleep 30

# Setup replication
log_info "Setting up replication..."
./mysql-cluster/scripts/setup-replication.sh

log_info "✅ MySQL cluster started successfully!"
echo ""
log_info "📊 Database endpoints:"
echo "   - MySQL Master: localhost:3306 (root/master_root_password)"
echo "   - MySQL Slave1: localhost:3307 (root/NO PASSWORD)"
echo "   - MySQL Slave2: localhost:3308 (root/NO PASSWORD)"
echo "   - MySQL Slave3: localhost:3309 (root/NO PASSWORD)"
echo ""
log_info "🛑 To stop: ../../scripts/stop.sh db"