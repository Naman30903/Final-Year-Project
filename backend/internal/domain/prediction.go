package domain

import "time"

// Prediction represents the ML model's prediction result
type Prediction struct {
	ID              string    `json:"id"`
	ArticleID       string    `json:"article_id"`
	RequestType     string    `json:"request_type"`      // "text" or "url"
	OriginalContent string    `json:"original_content"`  // Original text or URL
	
	// Prediction results
	Result          string    `json:"result"`              // "FAKE" or "REAL"
	Confidence      float64   `json:"confidence"`          // Confidence score (0-1)
	FakeProbability float64   `json:"fake_probability"`    // P(FAKE)
	RealProbability float64   `json:"real_probability"`    // P(REAL)
	ModelVersion    string    `json:"model_version"`       // Version of model used

	// Extracted metadata (populated for URL requests)
	ArticleTitle       string `json:"article_title,omitempty"`
	ArticleDescription string `json:"article_description,omitempty"`
	ArticleAuthor      string `json:"article_author,omitempty"`
	ArticleSource      string `json:"article_source,omitempty"`
	
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
