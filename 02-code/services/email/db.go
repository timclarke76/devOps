package main

import (
	"database/sql"
	"fmt"
)

func selectTemplate(name string) (*Template, error) {
	if db == nil {
		return nil, fmt.Errorf("Database not initialised")
	}

	var template Template
	template.Name = name

	if err := db.QueryRow(`
		SELECT id, subject, body
		FROM template
		WHERE name = $1
	`, name).Scan(&template.Id, &template.Subject, &template.Body); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		} else {
			return nil, fmt.Errorf("Could not select template:\n%w", err)
		}
	}

	return &template, nil
}

func insertSent(template int64, recipient string) error {
	if txn == nil {
		return fmt.Errorf("No active transaction")
	}

	if _, err := txn.Exec(`
		INSERT INTO sent (template, recipient)
		VALUES ($1, $2)
	`, template, recipient); err != nil {
		return fmt.Errorf("Could not insert sent record:\n%w", err)
	}

	return nil
}
