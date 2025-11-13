#!/bin/bash

set -e

echo "🚀 Starting Go Application..."

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

# Check if database network exists
if ! docker network ls | grep -q kafka-dbreplication-go_kafka-db-network; then
    log_error "Database network not found. Please start the database first with: ../../scripts/start.sh db"
    exit 1
fi

# Build and start application
log_info "Building and starting application..."
docker-compose -f app.docker-compose.yml up -d --build

# Wait for app to be ready
log_info "Waiting for application to start..."
for i in {1..30}; do
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        log_info "✅ Application is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        log_warn "⚠️ Application health check failed, but continuing..."
        break
    fi
    sleep 2
done

log_info "✅ Go application started successfully!"
echo ""
log_info "📊 Application endpoints:"
echo "   - Main: http://localhost:8080"
echo "   - Health: http://localhost:8080/health"
echo ""
log_info "🔧 Test commands:"
echo "   Create user: curl -X POST http://localhost:8080/api/users -H 'Content-Type: application/json' -d '{\"name\":\"Test\",\"email\":\"test@test.com\"}'"
echo "   List users: curl http://localhost:8080/api/users"
echo "   Replication status: curl http://localhost:8080/api/replication/status"
echo ""
log_info "📝 View logs: docker logs kafka-dbreplication-app -f"
echo ""
log_info "🛑 To stop: ../../scripts/stop.sh app"