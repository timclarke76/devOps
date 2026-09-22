package main

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/google/uuid"
)

var dynamoClient *dynamodb.Client

func initDb(ctx context.Context) error {
	cfg, err := config.LoadDefaultConfig(ctx)

	if err != nil {
		return fmt.Errorf("Unable to load config:\n%w", err)
	}

	dynamoClient = dynamodb.NewFromConfig(cfg)

	return nil
}

func insertRecord(ctx context.Context, service_name, level, data string) error {
	if dynamoClient == nil {
		return fmt.Errorf("DynamoDB not initialised")
	}

	now := time.Now().UTC()

	record := LogRecord{
		ID:          uuid.New().String(),
		ServiceName: service_name,
		Level:       level,
		Time:        now.Format(time.RFC3339),
		ExpiresAt:   now.Add(24 * time.Hour).Unix(),
	}

	av, _ := attributevalue.MarshalMap(record)

	var extraData map[string]interface{}
	err := json.Unmarshal([]byte(data), &extraData)

	if err == nil {
		extraAv, _ := attributevalue.MarshalMap(extraData)
		for key, value := range extraAv {
			if key == "ID" || key == "ServiceName" || key == "Time" {
				continue
			}
			av[key] = value
		}
	} else {
		av["Message"], _ = attributevalue.Marshal(data)
	}

	_, err = dynamoClient.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String("logging-table"),
		Item:      av,
	})

	return err
}

func GetRecentEmailLogs(ctx context.Context) ([]EmailLogResponse, error) {
	if dynamoClient == nil {
		return nil, fmt.Errorf("DynamoDB not initialised")
	}

	oneHourAgo := time.Now().UTC().Add(-1 * time.Hour).Format(time.RFC3339)
	keyEx := expression.Key("ServiceName").Equal(expression.Value("email")).
		And(expression.Key("Time").GreaterThanEqual(expression.Value(oneHourAgo)))

	filt := expression.Name("Level").Equal(expression.Value("INFO"))

	expr, err := expression.NewBuilder().WithKeyCondition(keyEx).WithFilter(filt).Build()
	if err != nil {
		return nil, err
	}

	input := &dynamodb.QueryInput{
		TableName:                 aws.String("logging-table"),
		IndexName:                 aws.String("ServiceTimeIndex"),
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		KeyConditionExpression:    expr.KeyCondition(),
		FilterExpression:          expr.Filter(),
	}

	result, err := dynamoClient.Query(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("query failed: %w", err)
	}

	var logs []EmailLogResponse
	err = attributevalue.UnmarshalListOfMaps(result.Items, &logs)
	if err != nil {
		return nil, fmt.Errorf("unmarshal failed: %w", err)
	}

	return logs, nil
}
