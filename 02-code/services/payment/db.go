package main

import (
	"fmt"
)

func insertPayment(booking_id string, amount_pence int64, status string) error {
	if txn == nil {
		return fmt.Errorf("No active transaction")
	}

	if _, err := txn.Exec(`
		INSERT INTO payment (booking_id, amount_pence, status)
		VALUES ($1, $2, $3)
	`, booking_id, amount_pence, status); err != nil {
		return fmt.Errorf("Could not insert payment:\n%w", err)
	}

	return nil
}
