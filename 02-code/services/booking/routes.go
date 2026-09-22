package main

import (
	"fmt"
	"encoding/json"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine) {
	router.GET("/checkAvailability", getCheckAvailability)
	router.POST("/createBooking", postCreateBooking)
}

func getCheckAvailability(c *gin.Context) {
	var req CheckAvailabilityRequest

	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": err.Error()})
		return
	}

	available, err := CheckRoomAvailability(
		req.Location,
		req.RoomName,
		req.BookingDate,
	)

	if err != nil {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	response := AvailabilityResponse{
		Available:   available,
		Location:    req.Location,
		RoomName:    req.RoomName,
		BookingDate: req.BookingDate,
	}

	c.JSON(http.StatusOK, response)
}

func postCreateBooking(c *gin.Context) {
	var req CreateBookingRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "details": err.Error()})
		return
	}

	var (
		booking      *Booking
		err          error
		roomResponse []*Room
		jsonData     []byte
	)

	if err := beginTxn(); err != nil {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	defer func() {
		if r := recover(); r != nil {
			rollbackTxn()
			panic(r)
		}
	}()

	if booking, err = CreateBooking(req); err != nil {
		rollbackTxn()
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	if roomResponse, err = callRoomService(booking.Location, booking.RoomName, booking.BookingDate); err != nil {
		rollbackTxn()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not fetch room details: " + err.Error()})
		return
	}

	if len(roomResponse) == 0 {
		rollbackTxn()
		c.JSON(http.StatusNotFound, gin.H{"error": "Room not found"})
		return
	}

	jsonData, err = json.Marshal(booking)

	if err != nil {
		log.Printf("Failed to marshal booking log: %v", err)
	} else {
		callLoggingService("INFO", string(jsonData))
	}

	bookingIDStr := fmt.Sprintf("%d", booking.ID)

	if err = callPaymentService(
		booking.CustomerEmail,
		bookingIDStr,
		int64(roomResponse[0].Price),
	); err != nil {
		rollbackTxn()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not initiate payment: " + err.Error()})
		return
	}

	if err = commitTxn(); err != nil {
		rollbackTxn()
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.JSON(http.StatusOK, booking)
}
