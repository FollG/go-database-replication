package mysql

import (
	"database/sql"
	"math/rand"
)

func (db *DB) Read(query string, args ...interface{}) (*sql.Rows, error) {
	if len(db.Slaves) == 0 {
		return db.Master.Query(query, args...)
	}

	// Простая round-robin балансировка
	slave := db.Slaves[rand.Intn(len(db.Slaves))]
	return slave.Query(query, args...)
}

func (db *DB) ReadRow(query string, args ...interface{}) (*sql.Row, error) {
	if len(db.Slaves) == 0 {
		return db.Master.QueryRow(query, args...), nil
	}

	slave := db.Slaves[rand.Intn(len(db.Slaves))]
	return slave.QueryRow(query, args...), nil
}
