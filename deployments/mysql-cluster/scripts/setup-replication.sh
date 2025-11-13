#!/bin/bash

set -e

echo "🔧 Setting up MySQL replication..."

# Colors for output
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

# Navigate to project root
cd "$(dirname "$0")/../.."

# Wait for MySQL instances to be ready
log_info "⏳ Waiting for MySQL containers to be ready..."

# Check if containers are running
for container in mysql-master mysql-slave1 mysql-slave2 mysql-slave3; do
    if ! docker ps | grep -q $container; then
        log_error "Container $container is not running!"
        exit 1
    fi
done

# Wait for MySQL master to be fully ready
log_info "Waiting for MySQL master to be fully initialized..."
for i in {1..60}; do
    if docker exec mysql-master mysqladmin ping -h localhost -uroot -pmaster_root_password --silent 2>/dev/null; then
        log_info "✅ MySQL master is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "MySQL master failed to start within 120 seconds"
        docker logs mysql-master
        exit 1
    fi
    sleep 2
done

# Additional wait for system tables to be initialized
sleep 10

# Setup master configuration
log_info "🎯 Configuring master replication..."
docker exec mysql-master mysql -uroot -pmaster_root_password -e "
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'replpassword';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
RESET MASTER;
"

# Get master status
log_info "📋 Getting master status..."
MASTER_STATUS=$(docker exec mysql-master mysql -uroot -pmaster_root_password -e "SHOW MASTER STATUS\G" 2>/dev/null || true)

if [ -z "$MASTER_STATUS" ]; then
    log_error "Failed to get master status"
    log_info "Trying again after restarting master..."
    docker restart mysql-master
    sleep 20
    MASTER_STATUS=$(docker exec mysql-master mysql -uroot -pmaster_root_password -e "SHOW MASTER STATUS\G")
fi

MASTER_LOG_FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
MASTER_LOG_POS=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')

echo "Master Log File: $MASTER_LOG_FILE"
echo "Master Log Position: $MASTER_LOG_POS"

# Setup each slave
setup_slave() {
    local slave_name=$1
    local server_id=$2

    log_info "🔧 Setting up $slave_name..."

    # Wait for slave to be ready
    for i in {1..30}; do
        if docker exec $slave_name mysqladmin ping -h localhost -uroot --silent 2>/dev/null; then
            break
        fi
        if [ $i -eq 30 ]; then
            log_warn "$slave_name is not responding, but continuing..."
            break
        fi
        sleep 2
    done

    # Temporarily disable read_only for setup
    docker exec $slave_name mysql -uroot -e "
    SET GLOBAL super_read_only=0;
    SET GLOBAL read_only=0;
    STOP SLAVE;
    RESET SLAVE ALL;
    " 2>/dev/null || log_warn "Could not reset slave on $slave_name"

    # Configure replication
    docker exec $slave_name mysql -uroot -e "
    CHANGE MASTER TO
    MASTER_HOST='mysql-master',
    MASTER_USER='repl',
    MASTER_PASSWORD='replpassword',
    MASTER_LOG_FILE='$MASTER_LOG_FILE',
    MASTER_LOG_POS=$MASTER_LOG_POS,
    MASTER_CONNECT_RETRY=10;
    START SLAVE;
    " 2>/dev/null || log_error "Failed to configure replication on $slave_name"

    # Wait for replication to start
    sleep 10

    # Enable read_only
    docker exec $slave_name mysql -uroot -e "
    SET GLOBAL read_only=1;
    SET GLOBAL super_read_only=1;
    " 2>/dev/null || true

    # Check slave status
    SLAVE_STATUS=$(docker exec $slave_name mysql -uroot -e "SHOW SLAVE STATUS\G" 2>/dev/null || true)

    if [ -n "$SLAVE_STATUS" ]; then
        IO_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_IO_Running:" | awk '{print $2}' || echo "No")
        SQL_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_SQL_Running:" | awk '{print $2}' || echo "No")

        if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
            log_info "✅ $slave_name replication is running"
        else
            log_warn "⚠️ $slave_name replication has issues - IO: $IO_RUNNING, SQL: $SQL_RUNNING"
            # Show errors if any
            LAST_ERROR=$(echo "$SLAVE_STATUS" | grep "Last_Error:" | awk '{print $2}' || echo "None")
            LAST_IO_ERROR=$(echo "$SLAVE_STATUS" | grep "Last_IO_Error:" | awk '{print $2}' || echo "None")
            if [ "$LAST_ERROR" != "None" ]; then
                log_warn "Last Error: $LAST_ERROR"
            fi
            if [ "$LAST_IO_ERROR" != "None" ]; then
                log_warn "Last IO Error: $LAST_IO_ERROR"
            fi
        fi
    else
        log_error "❌ Could not get slave status from $slave_name"
    fi
}

# Setup all slaves
log_info "🔄 Setting up replication on slaves..."
setup_slave "mysql-slave1" "2"
setup_slave "mysql-slave2" "3"
setup_slave "mysql-slave3" "4"

# Test replication
log_info "🧪 Testing replication..."
docker exec mysql-master mysql -uroot -pmaster_root_password -e "
USE test_db;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (name, email) VALUES ('replication_test', 'test@replication.com');
" 2>/dev/null && log_info "✅ Test data inserted on master" || log_error "Failed to insert test data"

# Check data on slaves
for slave in mysql-slave1 mysql-slave2 mysql-slave3; do
    log_info "Checking data on $slave:"
    if docker exec $slave mysql -uroot -e "SELECT name, email FROM test_db.users;" 2>/dev/null; then
        log_info "✅ $slave can read replicated data"
    else
        log_warn "❌ $slave cannot read data (replication might still be catching up)"
    fi
done

log_info "🎉 MySQL replication setup completed!"
echo ""
log_info "📊 Access points:"
echo "   - MySQL Master: localhost:3306 (root/master_root_password)"
echo "   - MySQL Slave1: localhost:3307 (root/NO PASSWORD)"
echo "   - MySQL Slave2: localhost:3308 (root/NO PASSWORD)"
echo "   - MySQL Slave3: localhost:3309 (root/NO PASSWORD)"
echo "   - App user: app_user/apppassword"