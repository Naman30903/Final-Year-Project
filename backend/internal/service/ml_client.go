package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/Naman30903/Final-Year-Project/internal/domain"
)

// MLClient handles communication with the ML model service.
type MLClient struct {
	baseURL     string
	httpClient  *http.Client
	apiKey      string
	predictPath string
	healthPath  string
}

// NewMLClient creates a new ML client.
func NewMLClient(baseURL string) *MLClient {
	return &MLClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		predictPath: "/predict",
		healthPath:  "/health",
	}
}

// WithAPIKey sets bearer token for upstream ML service calls.
func (c *MLClient) WithAPIKey(apiKey string) *MLClient {
	c.apiKey = apiKey
	return c
}

// WithPaths sets custom prediction and health paths.
func (c *MLClient) WithPaths(predictPath, healthPath string) *MLClient {
	if predictPath != "" {
		c.predictPath = normalizePath(predictPath)
	}
	if healthPath != "" {
		c.healthPath = normalizePath(healthPath)
	}
	return c
}

func normalizePath(path string) string {
	if strings.HasPrefix(path, "/") {
		return path
	}
	return "/" + path
}

func buildEndpoint(baseURL, path string) string {
	return strings.TrimRight(baseURL, "/") + normalizePath(path)
}

// ── Request / Response DTOs ──

// MLPredictionRequest is the payload for POST /predict.
type MLPredictionRequest struct {
	Text string `json:"text"`
}

// MLURLRequest is the payload for POST /predict/url.
type MLURLRequest struct {
	URL string `json:"url"`
}

// MLPredictionResponse represents the full response from the ML service.
type MLPredictionResponse struct {
	Result               string  `json:"result"`
	Confidence           float64 `json:"confidence"`
	ModelVersion         string  `json:"model_version,omitempty"`
	FakeProbability      float64 `json:"fake_probability"`
	RealProbability      float64 `json:"real_probability"`
	SourceURL            string  `json:"source_url,omitempty"`
	ExtractedTextPreview string  `json:"extracted_text_preview,omitempty"`
}

// ── Public methods ──

// Predict sends pre-extracted text to POST /predict.
func (c *MLClient) Predict(text string) (*domain.Prediction, error) {
	reqBody := MLPredictionRequest{Text: text}
	return c.doPredict(c.predictPath, reqBody)
}

// PredictURL sends a URL to POST /predict/url — the ML service scrapes it.
func (c *MLClient) PredictURL(articleURL string) (*domain.Prediction, error) {
	reqBody := MLURLRequest{URL: articleURL}
	return c.doPredict("/predict/url", reqBody)
}

// HealthCheck checks if ML service is available.
func (c *MLClient) HealthCheck() error {
	endpoint := buildEndpoint(c.baseURL, c.healthPath)
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

// ── Internal ──

func (c *MLClient) doPredict(path string, payload interface{}) (*domain.Prediction, error) {
	startTime := time.Now()

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	endpoint := buildEndpoint(c.baseURL, path)
	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if c.apiKey != "" {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.apiKey))
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", domain.ErrMLServiceUnavailable, err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("%w: status %d, body: %s",
			domain.ErrPredictionFailed, resp.StatusCode, string(body))
	}

	var mlResp MLPredictionResponse
	if err := json.Unmarshal(body, &mlResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	prediction := &domain.Prediction{
		Result:          mlResp.Result,
		Confidence:      mlResp.Confidence,
		FakeProbability: mlResp.FakeProbability,
		RealProbability: mlResp.RealProbability,
		ModelVersion:    mlResp.ModelVersion,
		ProcessingTime:  time.Since(startTime).Milliseconds(),
		CreatedAt:       time.Now(),
	}

	return prediction, nil
}
