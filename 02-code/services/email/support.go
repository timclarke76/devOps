package main

import (
	"bytes"
	"context"
	"database/sql"
	_ "embed"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"reflect"
	"strings"
	"time"

	_ "github.com/lib/pq"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
)

type OnEventFunc func(ctx context.Context, msg types.Message) error

type ServiceResponse struct {
	StatusCode int
	Body       []byte
}

const (
	REGISTRATION_QUEUE = "REGISTRATION_QUEUE"
	NEW_CUSTOMER_QUEUE = "NEW_CUSTOMER_QUEUE"
	PAYMENT_QUEUE      = "PAYMENT_QUEUE"
	BOOKING_QUEUE      = "BOOKING_QUEUE"

	CUSTOMER_SERVICE_ENDPOINT = "CUSTOMER_SERVICE_ENDPOINT"
	LOGGING_SERVICE_ENDPOINT  = "LOGGING_SERVICE_ENDPOINT"
	PAYMENT_SERVICE_ENDPOINT  = "PAYMENT_SERVICE_ENDPOINT"
	ROOM_SERVICE_ENDPOINT     = "ROOM_SERVICE_ENDPOINT"
	WEATHER_SERVICE_ENDPOINT  = "WEATHER_SERVICE_ENDPOINT"
)

var serviceName string

var queueURLs = map[string]string{
	REGISTRATION_QUEUE: "",
	NEW_CUSTOMER_QUEUE: "",
	PAYMENT_QUEUE:      "",
	BOOKING_QUEUE:      "",
}

var endpoints = map[string]string{
	CUSTOMER_SERVICE_ENDPOINT: "",
	LOGGING_SERVICE_ENDPOINT:  "",
	PAYMENT_SERVICE_ENDPOINT:  "",
	ROOM_SERVICE_ENDPOINT:     "",
	WEATHER_SERVICE_ENDPOINT:  "",
}

func initSupport(ctx context.Context) error {
	if err := initPostgreSQL(); err != nil {
		return err
	}

	if err := initSQS(ctx); err != nil {
		return err
	}

	if err := initEndpoints(); err != nil {
		return err
	}

	return nil
}

//================================
// PostgreSQL
//================================

const (
	maxConnectionAttempts = 5
	connectionWaitPeriod  = 2 * time.Second
)

var (
	db  *sql.DB
	txn *sql.Tx
	//go:embed init.sql
	createTableSQL string
)

func initPostgreSQL() error {
	connStr := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=require",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
	)

	var err error
	db, err = sql.Open("postgres", connStr)

	if err != nil {
		return fmt.Errorf("Failed to connect to database:\n%w", err)
	}

	for attemptIdx := 1; attemptIdx <= maxConnectionAttempts; attemptIdx++ {
		if db.Ping() == nil {
			break
		}

		if attemptIdx == maxConnectionAttempts {
			db = nil

			return fmt.Errorf(
				"Failed to connect to database after %d attempts",
				attemptIdx,
			)
		}

		time.Sleep(connectionWaitPeriod)
	}

	if _, err := db.Exec(createTableSQL); err != nil {
		db = nil
		return fmt.Errorf("Failed to create tables:\n%w", err)
	}

	return nil
}

func beginTxn() error {
	if db == nil {
		return fmt.Errorf("Database not initialised")
	}

	var err error
	txn, err = db.Begin()

	if err != nil {
		return fmt.Errorf("Could not begin txn:\n%w", err)
	}

	return nil
}

func rollbackTxn() {
	txn.Rollback()
	txn = nil
}

func commitTxn() error {
	if err := txn.Commit(); err != nil {
		return fmt.Errorf("Could not commit txn:\n%w", err)
	}

	txn = nil
	return nil
}

//================================
// SQS
//================================

const (
	maxMessages int32 = 10
	waitTime    int32 = 10
)

var sqsClient *sqs.Client

func initSQS(ctx context.Context) error {
	for key, _ := range queueURLs {
		queueURLs[key] = os.Getenv(key)

		if queueURLs[key] == "" {
			return fmt.Errorf("SQS environment variable %s not set", key)
		}
	}

	if cfg, err := config.LoadDefaultConfig(ctx); err != nil {
		return fmt.Errorf("Failed to load AWS SDK config:\n%w", err)
	} else {
		sqsClient = sqs.NewFromConfig(cfg)
	}

	return nil
}

func publish(ctx context.Context, queueKey string, message interface{}) error {
	if sqsClient == nil {
		return fmt.Errorf("SQS not initialized")
	}

	messageBody, err := json.Marshal(message)

	if err != nil {
		return fmt.Errorf("Failed to marshal message:\n%w", err)
	}

	if _, err = sqsClient.SendMessage(ctx, &sqs.SendMessageInput{
		QueueUrl:    aws.String(queueURLs[queueKey]),
		MessageBody: aws.String(string(messageBody)),
	}); err != nil {
		return fmt.Errorf("Failed to send message:\n%w", err)
	}

	return nil
}

func consume(ctx context.Context, queueKey string, onEventFunc OnEventFunc) {
	if sqsClient == nil {
		log.Fatal("SQS not initialized")
	}

	for {
		select {
		case <-ctx.Done():
			return
		default:
			// continuous polling
		}

		result, err := sqsClient.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
			QueueUrl:            aws.String(queueURLs[queueKey]),
			MaxNumberOfMessages: maxMessages,
			WaitTimeSeconds:     waitTime,
		})

		if err != nil {
			log.Printf("Error during ReceiveMessage, retrying in 5s:\n%w", err)
			time.Sleep(5 * time.Second)
			continue
		}

		for _, msg := range result.Messages {
			if err := onEventFunc(ctx, msg); err != nil {
				log.Printf(
					"Error processing message %s:\n%w",
					*msg.MessageId,
					err,
				)

				continue
			}

			if _, err := sqsClient.DeleteMessage(ctx, &sqs.DeleteMessageInput{
				QueueUrl:      aws.String(queueURLs[queueKey]),
				ReceiptHandle: msg.ReceiptHandle,
			}); err != nil {
				log.Printf(
					"Error deleting message %s:\n%w",
					*msg.MessageId,
					err,
				)
			}
		}
	}
}

//================================
// Endpoints
//================================

func initEndpoints() error {
	serviceName = os.Getenv("SERVICE_NAME")

	if serviceName == "" {
		return fmt.Errorf("SERVICE_NAME environment variable not set")
	}

	for key, _ := range endpoints {
		endpoints[key] = os.Getenv(key)

		if endpoints[key] == "" {
			return fmt.Errorf("Endpoint environment variable %s not set", key)
		}
	}

	return nil
}

func CallService(
	endpoint, method, path string,
	requestBody interface{},
) (*ServiceResponse, error) {
	fullURL := fmt.Sprintf("http://%s%s", endpoints[endpoint], path)

	var bodyBytes []byte

	if requestBody != nil {
		var err error

		if method == http.MethodGet {
			params := "?"
			v := reflect.ValueOf(requestBody)
			typeOfS := v.Type()

			for i := 0; i < v.NumField(); i++ {
				key := typeOfS.Field(i).Tag.Get("json")
				value := fmt.Sprintf("%v", v.Field(i).Interface())
				params += fmt.Sprintf("%s=%s&", key, url.QueryEscape(value))
			}

			params = strings.TrimRight(params, "&?")
			fullURL += params
			log.Printf("GET URL: %s", fullURL)
		} else {
			bodyBytes, err = json.Marshal(requestBody)

			if err != nil {
				str := fmt.Errorf(
					"Failed to marshal request body for %s %s:\n%w",
					method,
					fullURL,
					err,
				)

				log.Println(str)
				return nil, str
			}
		}
	}

	req, err := http.NewRequest(method, fullURL, bytes.NewBuffer(bodyBytes))

	if err != nil {
		str := fmt.Errorf(
			"Failed to create %s request to %s:\n%w",
			method,
			fullURL,
			err,
		)

		log.Println(str)
		return nil, str
	}

	if requestBody != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := http.DefaultClient.Do(req)

	if err != nil {
		str := fmt.Errorf(
			"Failed to perform %s request to %s:\n%w",
			method,
			fullURL,
			err,
		)

		log.Println(str)
		return nil, str
	}

	defer resp.Body.Close()
	respBody, err := io.ReadAll(resp.Body)

	if err != nil {
		str := fmt.Errorf(
			"Failed to read response body from %s %s:\n%w",
			method,
			fullURL,
			err,
		)

		log.Println(str)
		return nil, str
	}

	return &ServiceResponse{
		StatusCode: resp.StatusCode,
		Body:       respBody,
	}, nil
}

type LoggingStoreRequest struct {
	ServiceName string `json:"service_name" binding:"required"`
	Level       string `json:"level" binding:"required,oneof=DEBUG INFO WARN ERROR"`
	Data        string `json:"data" binding:"required"`
}

func callLoggingService(level, data string) error {
	request := LoggingStoreRequest{
		ServiceName: serviceName,
		Level:       level,
		Data:        data,
	}

	if _, err := CallService(
		LOGGING_SERVICE_ENDPOINT,
		http.MethodPost,
		"/store",
		request,
	); err != nil {
		return fmt.Errorf("Failed to call logging service:\n%w", err)
	}

	return nil
}

type WeatherForecastRequest struct {
	Location string `json:"location" binding:"required"`
	Date     string `json:"date" binding:"required"`
}

type WeatherForecastResponse struct {
	Location    string  `json:"location" binding:"required"`
	Date        string  `json:"date" binding:"required"`
	Temperature float32 `json:"temperature" binding:"required"`
}

func callWeatherService(location, date string) (float32, error) {
	request := WeatherForecastRequest{
		Location: location,
		Date:     date,
	}

	var (
		resp *ServiceResponse
		err  error
	)

	if resp, err = CallService(
		WEATHER_SERVICE_ENDPOINT,
		http.MethodGet,
		"/forecast",
		request,
	); err != nil {
		return 0.0, fmt.Errorf("Failed to call weather service:\n%w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return 0.0, fmt.Errorf(
			"Weather service returned status code %d",
			resp.StatusCode,
		)
	}

	var response WeatherForecastResponse
	if err = json.Unmarshal(resp.Body, &response); err != nil {
		return 0.0, fmt.Errorf(
			"Failed to unmarshal weather service response:\n%w",
			err,
		)
	}

	return response.Temperature, nil
}

type CallPaymentRequest struct {
	Email       string `json:"email" binding:"required,email"`
	BookingID   string `json:"booking_id" binding:"required"`
	AmountPence int64  `json:"amount_pence" binding:"required"`
}

func callPaymentService(email, bookingID string, amountPence int64) error {
	request := CallPaymentRequest{
		Email:       email,
		BookingID:   bookingID,
		AmountPence: amountPence,
	}

	if _, err := CallService(
		PAYMENT_SERVICE_ENDPOINT,
		http.MethodGet,
		"/",
		request,
	); err != nil {
		return fmt.Errorf("Failed to call payment service:\n%w", err)
	}

	return nil
}

type CallRoomRequest struct {
	Location string `json:"location" binding:"required"`
	Name     string `json:"name" binding:"required"`
	Date     string `json:"date" binding:"required"`
}

type RoomServiceResponse struct {
	Rooms []Room `json:"rooms" binding:"required"`
}

type Room struct {
	Location    string  `json:"location" binding:"required"`
	Name        string  `json:"name" binding:"required"`
	Capacity    int     `json:"capacity" binding:"required"`
	Price       int     `json:"price" binding:"required"`
	Temperature float32 `json:"temperature" binding:"required"`
}

func callRoomService(location, name, date string) ([]*Room, error) {
	// Log the request for debugging
	log.Printf("URL: %s", endpoints[ROOM_SERVICE_ENDPOINT])
	log.Printf("Calling room service with location=%s, name=%s, date=%s",
		location, name, date)

	request := CallRoomRequest{
		Location: location,
		Name:     name,
		Date:     date,
	}

	var (
		response *ServiceResponse
		err      error
		roomResp []*Room
	)

	if response, err = CallService(
		ROOM_SERVICE_ENDPOINT,
		http.MethodGet,
		"/",
		request,
	); err != nil {
		return nil, fmt.Errorf("Failed to call room service: %w", err)
	}

	// Log the raw response for debugging
	log.Printf("Room service response - Status: %d, Body: %s",
		response.StatusCode,
		string(response.Body))

	// CRITICAL: Check for HTTP errors
	if response.StatusCode != http.StatusOK {
		// Try to parse error message from response body
		errorMsg := string(response.Body)

		// Try to unmarshal as JSON error first
		var jsonError struct {
			Error   string `json:"error"`
			Message string `json:"message"`
		}
		if json.Unmarshal(response.Body, &jsonError) == nil {
			if jsonError.Error != "" {
				errorMsg = jsonError.Error
			} else if jsonError.Message != "" {
				errorMsg = jsonError.Message
			}
		}

		return nil, fmt.Errorf("Room service returned HTTP %d: %s",
			response.StatusCode, errorMsg)
	}

	if err := json.Unmarshal(response.Body, &roomResp); err != nil {
		// Log the actual response for debugging
		log.Printf("Failed to unmarshal room service response. Raw response: %s",
			string(response.Body))
		return nil, fmt.Errorf(
			"Failed to unmarshal room service response: %w",
			err,
		)
	}

	return roomResp, nil
}
