package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine) {
	router.POST("/store", postStore)
	router.GET("/emails", getEmails)
}

func postStore(c *gin.Context) {
	var req StoreRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		str := fmt.Sprintf("Invalid request: %v", err)
		log.Println(str)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := insertRecord(
		c.Request.Context(),
		req.ServiceName,
		req.Level,
		req.Data,
	); err != nil {
		log.Printf("Failed to insert record:\n%w", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.Status(http.StatusCreated)
}

func getEmails(c *gin.Context) {
	var (
		err       error
		emailLogs []EmailLogResponse
	)

	if emailLogs, err = GetRecentEmailLogs(c.Request.Context()); err != nil {
		log.Printf("Failed to get email logs:\n%w", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.JSON(http.StatusOK, emailLogs)
}
