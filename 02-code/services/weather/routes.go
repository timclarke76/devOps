package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine) {
	router.GET("/forecast", getForecast)
}

func getForecast(c *gin.Context) {
	var req ForecastRequest

	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	forecast, err := selectForecast(req.Location, req.Date)

	if err != nil {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	if forecast == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Forecast not found"})
		return
	}

	c.JSON(http.StatusOK, forecast)
}
