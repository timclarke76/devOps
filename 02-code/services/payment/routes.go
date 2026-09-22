package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine) {
	router.GET("/", getPayment)
}

func getPayment(c *gin.Context) {
	var req PaymentRequest

	if err := c.ShouldBindQuery(&req); err != nil {
		log.Println("Invalid payment request: ", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := beginTxn(); err != nil {
		log.Println("Failed to begin transaction: ", err.Error())
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	defer func() {
		if r := recover(); r != nil {
			rollbackTxn()
			panic(r)
		}
	}()

	err := insertPayment(req.BookingID, req.AmountPence, "completed")

	if err != nil {
		log.Println("Failed to insert payment: ", err.Error())
		callLoggingService("ERROR", "Failed to insert payment: "+err.Error())
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	jsonData, err := json.Marshal(req)

	if err != nil {
		log.Printf("Failed to marshal payment log: %v", err)
	} else {
		callLoggingService("INFO", string(jsonData))
	}

	if err = publishPayment(
		c.Request.Context(),
		req.Email,
		req.BookingID,
		req.AmountPence,
	); err != nil {
		log.Println("Failed to publish payment: ", err.Error())
		rollbackTxn()
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	if err = commitTxn(); err != nil {
		log.Println("Failed to commit transaction: ", err.Error())
		rollbackTxn()
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.Status(http.StatusOK)
}
