package mysql

import (
	"database/sql"
)

func (db *DB) Write(query string, args ...interface{}) (sql.Result, error) {
	return db.Master.Exec(query, args...)
}

func (db *DB) WriteWithTransaction(fn func(tx *sql.Tx) error) error {
	tx, err := db.Master.Begin()
	if err != nil {
		return err
	}

	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		}
	}()

	if err := fn(tx); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit()
}
