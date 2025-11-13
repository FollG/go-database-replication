-- MySQL 8.0 Initialization Script
-- This script creates the necessary users and databases

-- Wait for MySQL to be fully initialized
SET @max_attempts = 30;
SET @attempt = 0;

-- Create replication user with native password authentication
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'replpassword';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl'@'%';

-- Create application user
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED WITH mysql_native_password BY 'apppassword';
GRANT ALL PRIVILEGES ON *.* TO 'app_user'@'%';

-- Create test database and table
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;

CREATE TABLE IF NOT EXISTS users (
                                     id INT AUTO_INCREMENT PRIMARY KEY,
                                     name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

-- Reset master for replication
RESET MASTER;

-- Display status
SHOW MASTER STATUS;