package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
)

func onConsumeNewCustomerEvent(ctx context.Context, msg types.Message) error {
	var event NewCustomerEvent

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
		template *Template
		err      error
	)

	if template, err = selectTemplate("welcome"); err != nil {
		rollbackTxn()
		return fmt.Errorf("Failed to get welcome email template:\n%w", err)
	}

	if template == nil {
		rollbackTxn()
		return fmt.Errorf("Welcome email template not found")
	}

	var emailData = EmailLog{
		TemplateName: template.Name,
		Recipient:    event.Email,
		Subject:      template.Subject,
		Body:         template.Body,
		SentAt:       time.Now().UTC().Format(time.RFC3339),
	}

	jsonData, err := json.Marshal(emailData)
	if err != nil {
		log.Printf("Failed to marshal email log: %v", err)
		return fmt.Errorf("failed to marshal email log: %w", err)
	}

	callLoggingService("INFO", string(jsonData))

	if err = insertSent(template.Id, event.Email); err != nil {
		rollbackTxn()
		return fmt.Errorf("Failed to insert sent email record:\n%w", err)
	}

	if err = commitTxn(); err != nil {
		rollbackTxn()
		return fmt.Errorf("Failed to commit transaction:\n%w", err)
	}

	return nil
}

func onConsumeBookingEvent(ctx context.Context, msg types.Message) error {
	var event NewBookingEvent

	if err := json.Unmarshal([]byte(*msg.Body), &event); err != nil {
		log.Printf("Failed to unmarshal message: %v", err)
		return fmt.Errorf("Failed to unmarshal message:\n%w", err)
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

	var (
		template *Template
		err      error
	)

	if template, err = selectTemplate("booking_confirmation"); err != nil {
		rollbackTxn()
		log.Printf("Failed to get confirmation email template: %v", err)
		return fmt.Errorf("Failed to get confirmation email template:\n%w", err)
	}

	if template == nil {
		rollbackTxn()
		log.Printf("Booking confirmation email template not found")
		return fmt.Errorf("Booking confirmation email template not found")
	}

	log.Printf("Send booking confirmation email to %s:\n%+v", event.Email, template)

	var emailData = EmailLog{
		TemplateName: template.Name,
		Recipient:    event.Email,
		Subject:      template.Subject,
		Body:         template.Body,
		SentAt:       time.Now().UTC().Format(time.RFC3339),
	}

	jsonData, err := json.Marshal(emailData)
	if err != nil {
		log.Printf("Failed to marshal email log: %v", err)
		return fmt.Errorf("failed to marshal email log: %w", err)
	}

	callLoggingService("INFO", string(jsonData))

	if err = insertSent(template.Id, event.Email); err != nil {
		rollbackTxn()
		log.Printf("Failed to insert sent email record: %v", err)
		return fmt.Errorf("Failed to insert sent email record:\n%w", err)
	}

	if err = commitTxn(); err != nil {
		rollbackTxn()
		log.Printf("Failed to commit transaction: %v", err)
		return fmt.Errorf("Failed to commit transaction:\n%w", err)
	}

	return nil
}
