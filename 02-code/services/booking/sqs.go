package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strconv"

	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
)

func onConsumeEvent(ctx context.Context, msg types.Message) error {
	var event PaymentEvent

	if err := json.Unmarshal([]byte(*msg.Body), &event); err != nil {
		log.Printf("Failed to unmarshal message: %v", err)
		return fmt.Errorf("Failed to unmarshal message:\n%w", err)
	}

	idInt, err := strconv.Atoi(event.BookingID)
	if err != nil {
		return fmt.Errorf("invalid booking ID format: %w", err)
	}

	if err := beginTxn(); err != nil {
		log.Printf("Failed to begin transaction: %v", err)
		return fmt.Errorf("Failed to begin transaction:\n%w", err)
	}

	defer func() {
		if r := recover(); r != nil {
			rollbackTxn()
			panic(r)
		}
	}()

	if err := UpdateBookingStatus(
		idInt,
		"PAID",
	); err != nil {
		rollbackTxn()
		log.Printf("Failed to update booking status: %v", err)
		return fmt.Errorf("Failed to update booking status:\n%w", err)
	}

	if err := commitTxn(); err != nil {
		rollbackTxn()
		log.Printf("Failed to commit transaction: %v", err)
		return fmt.Errorf("Failed to commit transaction:\n%w", err)
	}

	if err := PublishNewBooking(ctx, event.Email); err != nil {
		return err
	}

	return nil
}

func PublishNewBooking(ctx context.Context, email string) error {
	event := NewPaymentEvent{
		Email: email,
	}

	if err := publish(ctx, BOOKING_QUEUE, event); err != nil {
		log.Printf("Failed to publish booking event: %v", err)
		return fmt.Errorf("Failed to publish booking event:\n%w", err)
	}

	log.Printf("Published new booking event for email: %s", email)

	return nil
}
