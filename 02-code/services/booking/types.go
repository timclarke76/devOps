package main

type Booking struct {
	ID            int    `json:"id" binding:"required"`
	CustomerEmail string `json:"customer_email" binding:"required,email"`
	Location      string `json:"location" binding:"required"`
	RoomName      string `json:"room_name" binding:"required"`
	BookingDate   string `json:"booking_date" binding:"required"`
	Status        string `json:"status" binding:"required,oneof=PENDING PAID"`
}

type CreateBookingRequest struct {
	CustomerEmail string `json:"customer_email" binding:"required,email"`
	Location      string `json:"location" binding:"required"`
	RoomName      string `json:"room_name" binding:"required"`
	BookingDate   string `json:"booking_date" binding:"required"`
}

type UpdateBookingStatusRequest struct {
	Status string `json:"status" binding:"required,oneof=PENDING PAID"`
}

type BookingEvent struct {
	EventType     string `json:"event_type" binding:"required,oneof=BOOKING_CREATED BOOKING_CONFIRMED BOOKING_CANCELLED BOOKING_PAID"`
	BookingID     int    `json:"booking_id" binding:"required"`
	CustomerEmail string `json:"customer_email" binding:"required,email"`
	Location      string `json:"location" binding:"required"`
	RoomName      string `json:"room_name" binding:"required"`
	BookingDate   string `json:"booking_date" binding:"required"`
	Status        string `json:"status" binding:"required"`
}

type CheckAvailabilityRequest struct {
	Location    string `json:"location" binding:"required"`
	RoomName    string `json:"room_name" binding:"required"`
	BookingDate string `json:"booking_date" binding:"required"`
}

type AvailabilityResponse struct {
	Available   bool   `json:"available" binding:"required"`
	Location    string `json:"location" binding:"required"`
	RoomName    string `json:"room_name" binding:"required"`
	BookingDate string `json:"booking_date" binding:"required"`
}

type RoomAvailability struct {
	Location    string `json:"location" binding:"required"`
	RoomName    string `json:"room_name" binding:"required"`
	BookingDate string `json:"booking_date" binding:"required"`
	Available   bool   `json:"available" binding:"required"`
}

type PaymentEvent struct {
	Email       string `json:"email" binding:"required,email"`
	BookingID   string `json:"booking_id" binding:"required"`
	AmountPence int64  `json:"amount_pence" binding:"required"`
}

type NewPaymentEvent struct {
	Email string `json:"email" binding:"required,email"`
}
