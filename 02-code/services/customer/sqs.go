package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
)

func onConsumeEvent(ctx context.Context, msg types.Message) error {
	var event RegistrationEvent

	if err := json.Unmarshal([]byte(*msg.Body), &event); err != nil {
		return fmt.Errorf("Failed to unmarshal message:\n%w", err)
	}

	if err := beginTxn(); err != nil {
		return fmt.Errorf("Failed to begin transaction:\n%w", err)
	}

	defer func() {
		if r := recover(); r != nil {
			rollbackTxn()
			panic(r)
		}
	}()

	var (
		success bool
		err     error
	)

	if success, err = insertProfile(
		event.Email,
		event.Name,
		"system",
	); err != nil {
		rollbackTxn()
		return fmt.Errorf("Failed to insert customer:\n%w", err)
	}

	if !success {
		rollbackTxn()
		return fmt.Errorf("Customer with email %s already exists", event.Email)
	}

	if err = commitTxn(); err != nil {
		rollbackTxn()
		return fmt.Errorf("Failed to commit transaction:\n%w", err)
	}

	if err = PublishNewCustomer(ctx, event.Email, event.Name); err != nil {
		return fmt.Errorf("Failed to publish new customer event:\n%w", err)
	}

	return nil
}

func PublishNewCustomer(ctx context.Context, email, name string) error {
	event := NewCustomerEvent{
		Email: email,
		Name:  name,
	}

	if err := publish(ctx, NEW_CUSTOMER_QUEUE, event); err != nil {
		return fmt.Errorf("Failed to publish new customer event:\n%w", err)
	}

	return nil
}
