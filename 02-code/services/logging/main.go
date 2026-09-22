package main

import (
	"context"
	"log"
	"os"

	"github.com/gin-gonic/gin"
)

var queueURLs map[string]string

func main() {
	ctx := context.Background()

	if err := initDb(ctx); err != nil {
		log.Fatalf("Initialisation error: %v", err)
	}

	router := gin.Default()

	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(200)
			return
		}

		c.Next()
	})

	initRoutes(router)
	router.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "status": "UP",
        })
    })

	port := os.Getenv("PORT")

	if port == "" {
		port = "8080"
	}

	log.Fatal(router.Run(":" + port))
}
