package domain

import "errors"

// News and Prediction related errors
var (
	ErrInvalidRequestType = errors.New("invalid request type: must be 'text' or 'url'")
	ErrEmptyContent       = errors.New("content cannot be empty")
	ErrURLScrapingFailed  = errors.New("failed to scrape content from URL")
	ErrMLServiceUnavailable = errors.New("ML service is unavailable")
	ErrPredictionFailed   = errors.New("prediction failed")
	ErrInvalidURL         = errors.New("invalid URL provided")
)
