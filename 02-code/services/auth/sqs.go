package main

import (
	"context"
	"fmt"
)

func publishUserRegistration(ctx context.Context, name, email string) error {
	event := RegistrationEvent{
		Email: email,
		Name:  name,
	}

	if err := publish(ctx, REGISTRATION_QUEUE, event); err != nil {
		return fmt.Errorf("Failed to publish user registration event:\n%w", err)
	}

	return nil
}
