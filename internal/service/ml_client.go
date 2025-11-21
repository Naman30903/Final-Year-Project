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
