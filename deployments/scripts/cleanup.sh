#!/bin/bash
# NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE
# EXECUTE ONLY IF U KNOW WHAT U DO EXECUTE ONLY IF U KNOW WHAT U DO EXECUTE ONLY IF U KNOW WHAT U DO
# NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE
#
#
# DELETES/CLEANS ALL YOUR DOCKER CONTAINERS
#
#
# NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE
# EXECUTE ONLY IF U KNOW WHAT U DO EXECUTE ONLY IF U KNOW WHAT U DO EXECUTE ONLY IF U KNOW WHAT U DO
# NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE NOT USE
set -e

echo "🧹 Cleaning up Kafka DB Replication Project..."

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

# Stop all services
log_info "Stopping all services..."
docker-compose -f deployments/full.docker-compose.yml down 2>/dev/null || true
docker-compose -f deployments/db.docker-compose.yml down 2>/dev/null || true
docker-compose -f deployments/app.docker-compose.yml down 2>/dev/null || true

# Remove containers
log_info "Removing containers..."
docker rm -f mysql-master mysql-slave1 mysql-slave2 mysql-slave3 kafka-dbreplication-app 2>/dev/null || true

# Remove volumes
log_info "Removing volumes..."
docker volume rm -f kafka-dbreplication-go_mysql_master_data 2>/dev/null || true
docker volume rm -f kafka-dbreplication-go_mysql_slave1_data 2>/dev/null || true
docker volume rm -f kafka-dbreplication-go_mysql_slave2_data 2>/dev/null || true
docker volume rm -f kafka-dbreplication-go_mysql_slave3_data 2>/dev/null || true

# Remove network
log_info "Removing network..."
docker network rm kafka-dbreplication-go_kafka-db-network 2>/dev/null || true

# Clean Docker system
log_info "Cleaning Docker system..."
docker system prune -f

log_info "✅ Cleanup completed!"