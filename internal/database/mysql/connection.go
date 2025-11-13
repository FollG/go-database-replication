package mysql

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	"github.com/FollG/go-database-replication/internal/config"
	_ "github.com/go-sql-driver/mysql"
)

type DB struct {
	Master *sql.DB
	Slaves []*sql.DB
}

func NewConnection(cfg config.DatabaseConfig) (*DB, error) {
	master, err := connect(cfg.Master, cfg.Username, cfg.Password, cfg.Database, cfg.MaxConns, cfg.MaxIdle)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to master: %v", err)
	}

	var slaves []*sql.DB
	for i, slaveAddr := range cfg.Slaves {
		slave, err := connect(slaveAddr, cfg.Username, cfg.Password, cfg.Database, cfg.MaxConns, cfg.MaxIdle)
		if err != nil {
			log.Printf("Warning: failed to connect to slave1 %d (%s): %v", i, slaveAddr, err)
			continue
		}
		slaves = append(slaves, slave)
	}

	if len(slaves) == 0 {
		log.Println("Warning: no slaves connected")
	}

	return &DB{
		Master: master,
		Slaves: slaves,
	}, nil
}

func connect(host, username, password, database string, maxConns, maxIdle int) (*sql.DB, error) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s)/%s?parseTime=true", username, password, host, database)
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(maxConns)
	db.SetMaxIdleConns(maxIdle)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		return nil, err
	}

	return db, nil
}

func (db *DB) Close() error {
	if err := db.Master.Close(); err != nil {
		return err
	}

	for _, slave := range db.Slaves {
		if err := slave.Close(); err != nil {
			return err
		}
	}

	return nil
}
