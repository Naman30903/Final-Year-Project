#!/bin/bash

# Fix ml_client.go file creation issue
# Run this script from the backend directory

echo "Fixing ml_client.go file..."

# Remove any corrupted file
rm -f internal/service/ml_client.go

# Create the ml_client.go file
cat > internal/service/ml_client.go << 'MLCLIENT'
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

type MLClient struct {
	baseURL    string
	httpClient *http.Client
	apiKey     string
}

func NewMLClient(baseURL string) *MLClient {
	return &MLClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

type MLPredictionRequest struct {
	Text string `json:"text"`
}

type MLPredictionResponse struct {
	Result       string  `json:"result"`
	Confidence   float64 `json:"confidence"`
	ModelVersion string  `json:"model_version,omitempty"`
}

func (c *MLClient) Predict(text string) (*domain.Prediction, error) {
	startTime := time.Now()
	reqBody := MLPredictionRequest{Text: text}
	jsonData, _ := json.Marshal(reqBody)
	
	endpoint := fmt.Sprintf("%s/predict", c.baseURL)
	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}
	
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", domain.ErrMLServiceUnavailable, err)
	}
	defer resp.Body.Close()
	
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("%w: status %d", domain.ErrPredictionFailed, resp.StatusCode)
	}
	
	var mlResp MLPredictionResponse
	json.Unmarshal(body, &mlResp)
	processingTime := time.Since(startTime).Milliseconds()
	
	return &domain.Prediction{
		Result:         mlResp.Result,
		Confidence:     mlResp.Confidence,
		ModelVersion:   mlResp.ModelVersion,
		ProcessingTime: processingTime,
		CreatedAt:      time.Now(),
	}, nil
}

func (c *MLClient) HealthCheck() error {
	endpoint := fmt.Sprintf("%s/health", c.baseURL)
	resp, err := c.httpClient.Get(endpoint)
	if err != nil {
		return fmt.Errorf("%w: %v", domain.ErrMLServiceUnavailable, err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return domain.ErrMLServiceUnavailable
	}
	return nil
}
MLCLIENT

echo "✅ ml_client.go created successfully!"
echo "Now running: go mod tidy"
go mod tidy

echo "Building application..."
go build -o bin/api ./cmd/api

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🚀 To run the server:"
    echo "   export ML_SERVICE_URL=http://localhost:8000"
    echo "   ./bin/api"
else
    echo "❌ Build failed. Check errors above."
fi
