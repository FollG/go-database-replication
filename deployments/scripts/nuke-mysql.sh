#!/bin/bash

set -e

echo "💥 Nuclear option: Complete MySQL reset..."

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

# Stop all containers
log_info "Stopping all containers..."
docker-compose -f deployments/db.docker-compose.yml down 2>/dev/null || true
docker-compose -f deployments/app.docker-compose.yml down 2>/dev/null || true

# Remove all containers
log_info "Removing all containers..."
docker rm -f mysql-master mysql-slave1 mysql-slave2 mysql-slave3 kafka-dbreplication-app 2>/dev/null || true

# Remove all volumes
log_info "Removing all volumes..."
docker volume rm -f \
    kafka-dbreplication-go_mysql_master_data \
    kafka-dbreplication-go_mysql_slave1_data \
    kafka-dbreplication-go_mysql_slave2_data \
    kafka-dbreplication-go_mysql_slave3_data 2>/dev/null || true

# Remove any orphaned volumes
docker volume prune -f

# Remove network
log_info "Removing network..."
docker network rm kafka-dbreplication-go_kafka-db-network 2>/dev/null || true

# Clean Docker system
log_info "Cleaning Docker system..."
docker system prune -f

log_info "✅ Nuclear cleanup completed!"
echo ""
log_info "Now run: ./scripts/start.sh db"