package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func initRoutes(router *gin.Engine) {
	router.POST("/register", postRegister)
	router.POST("/login", postLogin)
}

func postRegister(c *gin.Context) {
	var ctx = context.Background()
	var req RegistrationRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

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

	success, err := insertPassword(req.Email, req.Password)

	if err != nil {
		rollbackTxn()
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	if !success {
		rollbackTxn()
		c.JSON(http.StatusConflict, gin.H{"error": "User already exists"})
		return
	}

	if err = publishUserRegistration(ctx, req.Name, req.Email); err != nil {
		rollbackTxn()
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	if err = commitTxn(); err != nil {
		rollbackTxn()
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	c.Status(http.StatusCreated)
}

func postLogin(c *gin.Context) {
	var req LoginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

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

	verified, err := verifyUser(req.Username, req.Password)

	if err != nil {
		insertAttempt(req.Username, false, c.ClientIP())
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	if !verified {
		if err = insertAttempt(req.Username, false, c.ClientIP()); err != nil {
			c.AbortWithStatus(http.StatusInternalServerError)
		}

		var jsonData []byte

		jsonData, err = json.Marshal(req)

		if err != nil {
			log.Printf("Failed to marshal login log: %v", err)
		} else {
			callLoggingService("WARN", string(jsonData))
		}

		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Invalid credentials",
		})

		return
	}

	if err = insertAttempt(req.Username, true, c.ClientIP()); err != nil {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	if err = commitTxn(); err != nil {
		rollbackTxn()
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	response := LoginResponse{
		Token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock-jwt",
	}

	c.JSON(http.StatusOK, response)
}
