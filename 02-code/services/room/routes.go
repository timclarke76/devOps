package main

import (
	"fmt"
	"log"
	"math"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine) {
	router.GET("/", get)
	router.GET("/detail", getDetail)
}

func get(c *gin.Context) {
	var (
		rooms []Room
		err   error
	)

	var (
		location string
		name     string
		date     string
		exists   bool
	)

	location, exists = c.GetQuery("location")
	if !exists {
		location = ""
	}

	name, exists = c.GetQuery("name")
	if !exists {
		name = ""
	}

	date, exists = c.GetQuery("date")
	if !exists {
		date = time.Now().Format("2006-01-02")
	}

	if location != "" && name != "" {
		rooms, err = selectByLocationAndName(location, name)
	} else if location != "" {
		rooms, err = selectByLocation(location)
	} else if name != "" {
		rooms, err = selectByName(name)
	} else {
		rooms, err = selectAll()
	}

	if err != nil {
		callLoggingService("ERROR", "Failed to fetch rooms: "+err.Error())
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	for idx, room := range rooms {
		// callLoggingService("INFO", "Fetched room: "+room.Name+" in "+room.Location)
		temp, err := callWeatherService(room.Location, date)

		if err != nil {
			str := fmt.Sprintf(
				"Failed to fetch weather for %s on %s: %s",
				room.Location,
				date,
				err.Error(),
			)

			callLoggingService("ERROR", str)
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}

		originalPrice := float64(rooms[idx].Price)
		var multiplier float64 = 1.0
		tempDiff := math.Abs(float64(temp) - 21.0)

		log.Printf(
			"Temperature in %s on %s is %.2f°C, adjusting price accordingly",
			room.Location,
			date,
			temp,
		)

		if tempDiff >= 20 {
			multiplier = 1.5
		} else if tempDiff >= 10 {
			multiplier = 1.3
		} else if tempDiff >= 5 {
			multiplier = 1.2
		} else if tempDiff >= 2 {
			multiplier = 1.1
		}

		roundedPrice := math.Round(originalPrice * multiplier)
		rooms[idx].Price = int(roundedPrice)
		log.Printf(
			"Adjusted price for room %s in %s to %.2f",
			room.Name,
			room.Location,
			rooms[idx].Price,
		)

		rooms[idx].Temperature = temp
	}

	c.JSON(http.StatusOK, rooms)
}

func getDetail(c *gin.Context) {
	var (
		basicRooms []Room
		rooms []DetailedRoom
		err   error
	)

	var (
		location string
		name     string
		date     string
		exists   bool
	)

	location, exists = c.GetQuery("location")
	if !exists {
		location = ""
	}

	name, exists = c.GetQuery("name")
	if !exists {
		name = ""
	}

	date, exists = c.GetQuery("date")
	if !exists {
		date = time.Now().Format("2006-01-02")
	}

	if location != "" && name != "" {
		basicRooms, err = selectByLocationAndName(location, name)
	} else if location != "" {
		basicRooms, err = selectByLocation(location)
	} else if name != "" {
		basicRooms, err = selectByName(name)
	} else {
		basicRooms, err = selectAll()
	}

	if err != nil {
		callLoggingService("ERROR", "Failed to fetch rooms: "+err.Error())
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	for _, room := range basicRooms {
		rooms = append(rooms, DetailedRoom{
			Location: room.Location,
			Name:     room.Name,
			Capacity: room.Capacity,
			Price:    room.Price,
		})
	}

	for idx, room := range rooms {
		// callLoggingService("INFO", "Fetched room: "+room.Name+" in "+room.Location)
		temp, err := callWeatherService(room.Location, date)

		if err != nil {
			str := fmt.Sprintf(
				"Failed to fetch weather for %s on %s: %s",
				room.Location,
				date,
				err.Error(),
			)

			callLoggingService("ERROR", str)
			c.AbortWithStatus(http.StatusInternalServerError)
			return
		}

		originalPrice := float64(rooms[idx].Price)
		var multiplier float64 = 1.0
		tempDiff := math.Abs(float64(temp) - 21.0)

		log.Printf(
			"Temperature in %s on %s is %.2f°C, adjusting price accordingly",
			room.Location,
			date,
			temp,
		)

		if tempDiff >= 20 {
			multiplier = 1.5
		} else if tempDiff >= 10 {
			multiplier = 1.3
		} else if tempDiff >= 5 {
			multiplier = 1.2
		} else if tempDiff >= 2 {
			multiplier = 1.1
		}

		roundedPrice := math.Round(originalPrice * multiplier)
		rooms[idx].BasePrice = int(originalPrice)
		rooms[idx].TempAdjust = float32(roundedPrice - originalPrice)
		rooms[idx].TempPercentAdjust = int((roundedPrice - originalPrice) / originalPrice * 100)
		rooms[idx].Price = int(roundedPrice)
		log.Printf(
			"Adjusted price for room %s in %s to %.2f",
			room.Name,
			room.Location,
			rooms[idx].Price,
		)

		rooms[idx].Temperature = temp
	}

	c.JSON(http.StatusOK, rooms)
}
