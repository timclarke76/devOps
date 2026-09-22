package main

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine) {
	router.POST("/profile", postProfile)
}

func postProfile(c *gin.Context) {
	var req ProfileRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, err := selectProfile(req.Email)

	if err != nil {
		CallService(LOGGING_SERVICE_ENDPOINT, "POST", "/store", gin.H{
			"service_name": "customer",
			"level":        "ERROR",
			"data":         fmt.Sprintf("Failed to select profile:\n%v", err),
		})

		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.JSON(http.StatusOK, profile)
}
