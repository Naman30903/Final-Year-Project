package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/Naman30903/Final-Year-Project/internal/domain"
)

// MLClient handles communication with the ML model service
type MLClient struct {
	baseURL    string
	httpClient *http.Client
	apiKey     string // Optional: if you add authentication later
}

// NewMLClient creates a new ML client
func NewMLClient(baseURL string) *MLClient {
	return &MLClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second, // 30s timeout for ML processing
		},
	}
}

// MLPredictionRequest represents the request to ML service
type MLPredictionRequest struct {
	Text string `json:"text"`
}

// MLPredictionResponse represents the response from ML service
// TODO: Update this structure based on your actual ML model output
type MLPredictionResponse struct {
	Result       string  `json:"result"`     // "FAKE" or "REAL" or custom labels
	Confidence   float64 `json:"confidence"` // 0.0 to 1.0
	ModelVersion string  `json:"model_version,omitempty"`
}

// Predict sends text to ML model and gets prediction
func (c *MLClient) Predict(text string) (*domain.Prediction, error) {
	startTime := time.Now()

	// Prepare request
	reqBody := MLPredictionRequest{
		Text: text,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	// Send request to ML service
	endpoint := fmt.Sprintf("%s/predict", c.baseURL)
	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if c.apiKey != "" {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.apiKey))
	}

	// Execute request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", domain.ErrMLServiceUnavailable, err)
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("%w: status %d, body: %s", domain.ErrPredictionFailed, resp.StatusCode, string(body))
	}

	// Parse response
	var mlResp MLPredictionResponse
	if err := json.Unmarshal(body, &mlResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	// Calculate processing time
	processingTime := time.Since(startTime).Milliseconds()

	// Create prediction domain object
	prediction := &domain.Prediction{
		Result:         mlResp.Result,
		Confidence:     mlResp.Confidence,
		ModelVersion:   mlResp.ModelVersion,
		ProcessingTime: processingTime,
		CreatedAt:      time.Now(),
	}

	return prediction, nil
}

// HealthCheck checks if ML service is available
func (c *MLClient) HealthCheck() error {
	endpoint := fmt.Sprintf("%s/health", c.baseURL)
	resp, err := c.httpClient.Get(endpoint)
	if err != nil {
		return fmt.Errorf("%w: %v", domain.ErrMLServiceUnavailable, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("%w: status %d", domain.ErrMLServiceUnavailable, resp.StatusCode)
	}

	return nil
}
