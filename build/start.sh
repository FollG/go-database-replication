#!/bin/bash
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}  ____           __  __       _        _                      ${NC}"
echo -e "${YELLOW} |  _ \ ___  ___|  \/  | __ _| | _____(_)_ __ ___   _____   __${NC}"
echo -e "${YELLOW} | |_) / _ \/ __| |\/| |/ _  | |/ / __| | '_   _ \ / _ \ \ / /${NC}"
echo -e "${YELLOW} |  _ < (_) \__ \ |  | | (_| |   <\__ \ | | | | | | (_) \ V / ${NC}"
echo -e "${YELLOW} |_| \_\___/|___/_|  |_|\__,_|_|\_\___/_|_| |_| |_|\___/ \_/  ${NC}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "📈 Starting everything..."

# Останавливаем и очищаем всё
docker-compose down -v 2>/dev/null || true

# Запускаем
docker-compose up -d

# Ждём
log_info "⏳ Waiting for services to start..."
sleep 5

# Настраиваем репликацию
./setup-replication.sh

log_info "✅ Everything is running!"
echo ""
echo "📊 Services:"
echo "   - App: http://localhost:8080"
echo "   - MySQL Master: localhost:3306 (root/rootpassword)"
echo "   - MySQL Slaves: localhost:3307,3308,3309 (root/NO PASSWORD)"