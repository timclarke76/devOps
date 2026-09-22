package main

import (
	"fmt"
	"log"
)

func CheckRoomAvailability(location, roomName, date string) (bool, error) {
	if db == nil {
		return false, fmt.Errorf("Database not initialised")
	}

	var count int

	err := db.QueryRow(`
		SELECT COUNT(*) 
		FROM booking 
		WHERE location = $1 
		AND room_name = $2 
		AND booking_date = $3
	`, location, roomName, date).Scan(&count)

	if err != nil {
		return false, fmt.Errorf("Could not check room availability: %w", err)
	}

	return count == 0, nil
}

func CreateBooking(req CreateBookingRequest) (*Booking, error) {
	if txn == nil {
		return nil, fmt.Errorf("Txn not initialised")
	}

	available, err := CheckRoomAvailability(
		req.Location,
		req.RoomName,
		req.BookingDate,
	)

	if err != nil {
		return nil, fmt.Errorf("Failed to check availability: %w", err)
	}

	if !available {
		return nil, fmt.Errorf("Room %s in %s is not available on %s",
			req.RoomName, req.Location, req.BookingDate)
	}

	var bookingID int
	var createdAt string

	err = txn.QueryRow(`
		INSERT INTO booking (customer_email, location, room_name, booking_date, status)
		VALUES ($1, $2, $3, $4, 'PENDING')
		RETURNING id, created_at
	`, req.CustomerEmail, req.Location, req.RoomName, req.BookingDate).Scan(&bookingID, &createdAt)

	if err != nil {
		return nil, fmt.Errorf("Could not create booking: %w", err)
	}

	log.Printf("Created booking ID %d at %s", bookingID, createdAt)

	booking := &Booking{
		ID:            bookingID,
		CustomerEmail: req.CustomerEmail,
		Location:      req.Location,
		RoomName:      req.RoomName,
		BookingDate:   req.BookingDate,
		Status:        "PENDING",
	}

	return booking, nil
}

func UpdateBookingStatus(bookingID int, status string) error {
	if txn == nil {
		return fmt.Errorf("Txn not initialised")
	}

	log.Printf("Updating booking ID %s to status %s", bookingID, status)

	if _, err := txn.Exec(`
		UPDATE booking 
		SET status = $1
		WHERE id = $2
	`, status, bookingID); err != nil {
		log.Println("Error updating booking status:", err)
		return fmt.Errorf("Could not update booking status: %w", err)
	}

	return nil
}
