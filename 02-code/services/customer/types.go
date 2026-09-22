package main

type RegistrationEvent struct {
	Email string `json:"email" binding:"required,email"`
	Name  string `json:"name" binding:"required"`
}

type NewCustomerEvent struct {
	Email string `json:"email" binding:"required,email"`
	Name  string `json:"name" binding:"required"`
}

type ProfileRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type Profile struct {
	Email string `json:"email" binding:"required,email"`
	Name  string `json:"name" binding:"required"`
	Theme string `json:"theme" binding:"required"`
}
