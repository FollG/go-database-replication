#!/bin/bash

set -e

echo "🚀 Starting Kafka DB Replication Go Project..."

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Parse command line arguments
MODE=${1:-"full"}  # full, db, app

case $MODE in
    "db")
        log_info "Starting only database cluster..."
        ./deployments/scripts/start-db.sh
        ;;
    "app")
        log_info "Starting only application..."
        ./deployments/scripts/start-app.sh
        ;;
    "full"|*)
        log_info "Starting full stack (DB + App)..."
        ./deployments/scripts/start-all.sh
        ;;
esac