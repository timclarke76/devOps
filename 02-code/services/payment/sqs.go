package main

import (
	"context"
	"fmt"
)

func publishPayment(
	ctx context.Context,
	email, booking_id string,
	amount_pence int64,
) error {
	event := PaymentEvent{
		Email:       email,
		BookingID:   booking_id,
		AmountPence: amount_pence,
	}

	if err := publish(ctx, PAYMENT_QUEUE, event); err != nil {
		return fmt.Errorf("Failed to publish payment event:\n%w", err)
	}

	return nil
}
