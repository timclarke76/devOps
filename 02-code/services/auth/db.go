package main

import (
	"database/sql"
	"fmt"

	"github.com/lib/pq"
)

func insertPassword(email, password string) (bool, error) {
	if txn == nil {
		return false, fmt.Errorf("No active transaction")
	}

	var (
		err  error
		hash string
	)

	if hash, err = hashPassword(password); err != nil {
		return false, fmt.Errorf("Failed to hash password\n%w", err)
	}

	if _, err = txn.Exec(`
		INSERT INTO password (email, hash) 
		VALUES ($1, $2)
	`, email, hash); err != nil {
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			return false, nil // Duplicate email
		} else {
			return false, fmt.Errorf("Could not insert password:\n%w", err)
		}
	}

	return true, nil
}

func verifyUser(email string, password string) (bool, error) {
	if db == nil {
		return false, fmt.Errorf("Database not initialised")
	}

	var hash string

	if err := db.QueryRow(`
		SELECT hash
		FROM password
		WHERE email = $1
	`, email).Scan(&hash); err != nil {
		if err == sql.ErrNoRows {
			return false, nil
		} else {
			return false, fmt.Errorf("Could not select password:\n%w", err)
		}
	}

	return compareHash(password, hash), nil
}

func insertAttempt(email string, success bool, ip string) error {
	if txn == nil {
		return fmt.Errorf("No active transaction")
	}

	if _, err := txn.Exec(`
		INSERT INTO attempt (email, success, ip_address)
		VALUES ($1, $2, $3)
	`, email, success, ip); err != nil {
		return fmt.Errorf("Could not insert attempt:\n%w", err)
	}

	return nil
}
