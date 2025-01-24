package utils

import (
	"encoding/json"

	"github.com/nats-io/nats.go/micro"
)

type ServiceRequest struct {
	Args    []string `json:"args"`
	Body    string   `json:"body"`
	Channel string   `json:"channel"`
	Timeout int      `json:"timeout"`
}

type ServiceResponseModel struct {
	HasError     bool   `json:"hasError"`
	ErrorMessage string `json:"errorMessage"`
	Data         string `json:"data"`
}

type Page[K any] struct {
	TotalPages  int `json:"totalPages"`
	TotalItems  int `json:"totalItems"`
	CurrentPage int `json:"currentPage"`
	Items       []K `json:"items"`
}

func ServiceResponse(req micro.Request, data any) {
	// Marshal the data to JSON
	response, err := json.Marshal(data)
	if err != nil {

		ServiceResponseError(req, "Error marshalling data to JSON")
		return
	}

	req.RespondJSON(ServiceResponseModel{
		HasError:     false,
		ErrorMessage: "",
		Data:         string(response),
	})
}

func ServiceResponseError(req micro.Request, errorMessage string) {
	req.RespondJSON(ServiceResponseModel{
		HasError:     true,
		ErrorMessage: errorMessage,
		Data:         "",
	})
}
