package main

type StoreRequest struct {
	ServiceName string `json:"service_name" binding:"required"`
	Level       string `json:"level" binding:"required,oneof=DEBUG INFO WARN ERROR"`
	Data        string `json:"data" binding:"required"`
}

type LogRecord struct {
	ID          string `dynamodbav:"ID,omitempty"`
	ServiceName string `dynamodbav:"ServiceName"`
	Level       string `dynamodbav:"Level"`
	Data        string `dynamodbav:"Data"`
	Time        string `dynamodbav:"Time"`
	ExpiresAt   int64  `dynamodbav:"ExpiresAt"`
}

type EmailLogResponse struct {
	ID           string `dynamodbav:"ID"`
	ServiceName  string `dynamodbav:"ServiceName"`
	Level        string `dynamodbav:"Level"`
	Time         string `dynamodbav:"Time"`
	TemplateName string `dynamodbav:"template_name"`
	Recipient    string `dynamodbav:"recipient"`
	Subject      string `dynamodbav:"subject"`
	Body         string `dynamodbav:"body"`
	SentAt       string `dynamodbav:"sent_at"`
}
