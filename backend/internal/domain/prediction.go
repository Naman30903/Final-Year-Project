package domain

import "time"

// Prediction represents the ML model's prediction result
type Prediction struct {
	ID              string    `json:"id"`
	ArticleID       string    `json:"article_id"`
	RequestType     string    `json:"request_type"`      // "text" or "url"
	OriginalContent string    `json:"original_content"`  // Original text or URL
	
	// Prediction results - will be defined after discussion with team
	Result          string    `json:"result"`            // e.g., "FAKE", "REAL", etc.
	Confidence      float64   `json:"confidence"`        // Confidence score (0-1)
	ModelVersion    string    `json:"model_version"`     // Version of model used
	
	// Metadata
	ProcessingTime  int64     `json:"processing_time_ms"` // Time taken in milliseconds
	CreatedAt       time.Time `json:"created_at"`
}

// PredictionResponse represents the API response for prediction
type PredictionResponse struct {
	Success    bool        `json:"success"`
	Prediction *Prediction `json:"prediction,omitempty"`
	Error      string      `json:"error,omitempty"`
}
