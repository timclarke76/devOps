package main

type ForecastRequest struct {
	Location string `json:"location" form:"location" binding:"required"`
	Date     string `json:"date" form:"date" binding:"required"`
}

type Forecast struct {
	Location    string  `json:"location" binding:"required"`
	Date        string  `json:"date" binding:"required"`
	Temperature float32 `json:"temperature" binding:"required"`
}
