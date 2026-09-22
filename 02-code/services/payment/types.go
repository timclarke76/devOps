package main

type PaymentRequest struct {
	Email       string `json:"email" form:"email" binding:"required,email"`
	BookingID   string `json:"booking_id" form:"booking_id" binding:"required"`
	AmountPence int64  `json:"amount_pence" form:"amount_pence" binding:"required"`
}

type PaymentEvent struct {
	Email       string `json:"email" binding:"required,email"`
	BookingID   string `json:"booking_id" binding:"required"`
	AmountPence int64  `json:"amount_pence" binding:"required"`
}
