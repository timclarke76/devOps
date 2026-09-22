package main

import (
	"database/sql"
	"fmt"

	"github.com/lib/pq"
)

func insertProfile(email, name, theme string) (bool, error) {
	if txn == nil {
		return false, fmt.Errorf("No active transaction")
	}

	if _, err := txn.Exec(`
		INSERT INTO profile (email, name, theme)
		VALUES ($1, $2, $3)
	`, email, name, theme); err != nil {
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			return false, nil // Duplicate email
		} else {
			return false, fmt.Errorf("Could not insert user:\n%w", err)
		}
	}

	return true, nil
}

func selectProfile(email string) (*Profile, error) {
	if db == nil {
		return nil, fmt.Errorf("Database not initialised")
	}

	var profile Profile
	profile.Email = email

	if err := db.QueryRow(`
		SELECT name, theme 
		FROM profile
		WHERE email = $1
	`, email).Scan(&profile.Name, &profile.Theme); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		} else {
			return nil, fmt.Errorf("Could not select profile:\n%w", err)
		}
	}

	return &profile, nil
}
