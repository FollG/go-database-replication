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


log_info "🔧 Setting up MySQL replication..."
log_info "⏳ Waiting for MySQL to start..."
sleep 30

log_info "🔍 Checking MySQL servers..."
for container in mysql-master mysql-slave1 mysql-slave2 mysql-slave3; do
    if docker exec $container mysqladmin ping -h localhost --silent 2>/dev/null; then
        log_info "✅ $container is running"
    else
        log_error "❌ $container is not responding"
        exit 1
    fi
done

log_info "🔍 Checking GTID settings on master..."
docker exec mysql-master mysql -uroot -prootpassword -e "SHOW VARIABLES LIKE 'gtid_mode';"
docker exec mysql-master mysql -uroot -prootpassword -e "SHOW VARIABLES LIKE 'enforce_gtid_consistency';"

for slave in mysql-slave1 mysql-slave2 mysql-slave3; do
    log_info "🔍 Checking GTID settings on $slave..."
    docker exec $slave mysql -uroot -e "SHOW VARIABLES LIKE 'gtid_mode';"
    docker exec $slave mysql -uroot -e "SHOW VARIABLES LIKE 'enforce_gtid_consistency';"
done

log_info "🗄️ Creating test_db on master..."
docker exec mysql-master mysql -uroot -prootpassword -e "CREATE DATABASE IF NOT EXISTS test_db;"

log_info "🎯 Configuring master..."
docker exec mysql-master mysql -uroot -prootpassword -e "
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'replpassword';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
"

log_info "🗄️ Creating test_db on all slaves..."
for slave in mysql-slave1 mysql-slave2 mysql-slave3; do
    echo "Creating database on $slave..."
    docker exec $slave mysql -uroot -e "
    SET GLOBAL super_read_only = 0;
    SET GLOBAL read_only = 0;
    CREATE DATABASE IF NOT EXISTS test_db;
    SET GLOBAL read_only = 1;
    SET GLOBAL super_read_only = 1;
    " && log_info "✅ Database created on $slave" || log_warn "⚠️ Could not create database on $slave (might already exist)"
done

log_info "📋 Getting master GTID position..."
MASTER_GTID_PURGED=$(docker exec mysql-master mysql -uroot -prootpassword -e "SHOW MASTER STATUS\G" | grep "Executed_Gtid_Set" | awk '{print $2}')

log_info "Master GTID Position: $MASTER_GTID_PURGED"

setup_slave() {
    local slave_name=$1

    log_info "🔧 Setting up $slave_name with GTID..."

    docker exec $slave_name mysql -uroot -e "
    SET GLOBAL super_read_only = 0;
    SET GLOBAL read_only = 0;
    "

    docker exec $slave_name mysql -uroot -e "
    STOP SLAVE;
    RESET SLAVE ALL;
    SET GLOBAL gtid_purged='$MASTER_GTID_PURGED';
    CHANGE MASTER TO
    MASTER_HOST='mysql-master',
    MASTER_USER='repl',
    MASTER_PASSWORD='replpassword',
    MASTER_AUTO_POSITION=1;
    START SLAVE;
    "

    docker exec $slave_name mysql -uroot -e "
    SET GLOBAL read_only = 1;
    SET GLOBAL super_read_only = 1;
    "

    sleep 10
    log_info "📊 Checking replication status for $slave_name..."
    SLAVE_STATUS=$(docker exec $slave_name mysql -uroot -e "SHOW SLAVE STATUS\G")

    IO_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_IO_Running:" | awk '{print $2}')
    SQL_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_SQL_Running:" | awk '{print $2}')
    LAST_IO_ERROR=$(echo "$SLAVE_STATUS" | grep "Last_IO_Error:" | awk '{print $2}')
    LAST_SQL_ERROR=$(echo "$SLAVE_STATUS" | grep "Last_SQL_Error:" | awk '{print $2}')

    if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
        log_info "✅ $slave_name replication is running"
    else
        log_error "❌ $slave_name replication issues - IO: $IO_RUNNING, SQL: $SQL_RUNNING"
        if [ -n "$LAST_IO_ERROR" ] && [ "$LAST_IO_ERROR" != "NULL" ]; then
            log_error "   Last IO Error: $LAST_IO_ERROR"
        fi
        if [ -n "$LAST_SQL_ERROR" ] && [ "$LAST_SQL_ERROR" != "NULL" ]; then
            log_error "   Last SQL Error: $LAST_SQL_ERROR"
        fi
    fi

    log_info "🔍 GTID status for $slave_name:"
    docker exec $slave_name mysql -uroot -e "SHOW SLAVE STATUS\G" | grep -E "Retrieved_Gtid_Set|Executed_Gtid_Set"
}

setup_slave "mysql-slave1"
setup_slave "mysql-slave2"
setup_slave "mysql-slave3"

log_info "🧪 Creating table and testing replication..."
docker exec mysql-master mysql -uroot -prootpassword -e "
USE test_db;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users (name, email) VALUES ('test_user', 'test@example.com');
"

sleep 5

for slave in mysql-slave1 mysql-slave2 mysql-slave3; do
    log_info "🔍 Checking data on $slave:"
    if docker exec $slave mysql -uroot -e "SELECT * FROM test_db.users;" 2>/dev/null; then
        log_info "✅ $slave can read replicated data"
    else
        log_error "❌ $slave cannot read data"
    fi
done

log_info "🎉 MySQL replication setup completed!"