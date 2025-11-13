#!/bin/bash

set -e

echo "🛑 Stopping Kafka DB Replication Go Project..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Parse command line arguments
MODE=${1:-"full"}  # full, db, app

case $MODE in
    "db")
        log_info "Stopping only database cluster..."
        ./deployments/scripts/stop-db.sh
        ;;
    "app")
        log_info "Stopping only application..."
        ./deployments/scripts/stop-app.sh
        ;;
    "full"|*)
        log_info "Stopping full stack..."
        ./deployments/scripts/stop-all.sh
        ;;
esac