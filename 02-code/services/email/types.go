package main

type NewCustomerEvent struct {
	Email string `json:"email" binding:"required,email"`
	Name  string `json:"name" binding:"required"`
}

type NewBookingEvent struct {
	Email string `json:"email" binding:"required,email"`
}

type Template struct {
	Id      int64
	Name    string
	Subject string
	Body    string
}

type EmailLog struct {
	TemplateName string `json:"template_name"`
	Recipient    string `json:"recipient"`
	Subject      string `json:"subject"`
	Body         string `json:"body"`
	SentAt       string `json:"sent_at"`
}
