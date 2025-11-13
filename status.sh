#!/bin/bash

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

log_info "🔍 Checking status..."

echo "Containers:"
docker-compose ps

echo ""
log_info "🔧 Replication status:"

for slave in mysql-slave1 mysql-slave2 mysql-slave3; do
    echo "$slave:"
    docker exec $slave mysql -uroot -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running" || echo "Not running"
    echo ""
done

log_info "🌐 App health:"
curl -s http://localhost:8080/health || log_warn "App not ready"