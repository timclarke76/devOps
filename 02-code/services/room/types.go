package main

type DetailedRoom struct {
	Location    string  `json:"location" binding:"required"`
	Name        string  `json:"name" binding:"required"`
	Capacity    int     `json:"capacity" binding:"required"`
	Price       int     `json:"price" binding:"required"`
	Temperature float32 `json:"temperature" binding:"required"`
	BasePrice   int     `json:"base_price" binding:"required"`
	TempAdjust  float32 `json:"temp_adjust" binding:"required"`
	TempPercentAdjust int `json:"temp_percent_adjust" binding:"required"`
}
