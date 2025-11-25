package service

import (
	"fmt"
	"time"

	"github.com/Naman30903/Final-Year-Project/internal/domain"
	"github.com/google/uuid"
)

// NewsRepository defines the interface for news data storage
type NewsRepository interface {
	SavePrediction(prediction *domain.Prediction) error
	GetPredictionByID(id string) (*domain.Prediction, error)
	GetAllPredictions() ([]*domain.Prediction, error)
}

// NewsService handles news analysis business logic
type NewsService struct {
	mlClient   *MLClient
	scraper    *ScraperService
	repository NewsRepository
}

// NewNewsService creates a new news service
func NewNewsService(mlClient *MLClient, scraper *ScraperService, repo NewsRepository) *NewsService {
	return &NewsService{
		mlClient:   mlClient,
		scraper:    scraper,
		repository: repo,
	}
}

// AnalyzeNews analyzes news article or URL for fake news detection
func (s *NewsService) AnalyzeNews(req *domain.AnalysisRequest) (*domain.Prediction, error) {
	// Validate request
	if err := req.Validate(); err != nil {
		return nil, err
	}

	var textContent string
	var err error

	// Extract content based on type
	switch req.Type {
	case "text":
		textContent = req.Content
	case "url":
		// Scrape content from URL
		textContent, err = s.scraper.ScrapeURL(req.Content)
		if err != nil {
			return nil, err
		}
	default:
		return nil, domain.ErrInvalidRequestType
	}

	// Get prediction from ML model
	prediction, err := s.mlClient.Predict(textContent)
	if err != nil {
		return nil, err
	}

	// Enrich prediction with request metadata
	prediction.ID = uuid.New().String()
	prediction.RequestType = req.Type
	prediction.OriginalContent = req.Content
	prediction.CreatedAt = time.Now()

	// Save prediction to repository
	if err := s.repository.SavePrediction(prediction); err != nil {
		// Log error but don't fail the request
		fmt.Printf("Warning: Failed to save prediction: %v\n", err)
	}

	return prediction, nil
}

// GetPrediction retrieves a prediction by ID
func (s *NewsService) GetPrediction(id string) (*domain.Prediction, error) {
	return s.repository.GetPredictionByID(id)
}

// GetHistory retrieves all prediction history
func (s *NewsService) GetHistory() ([]*domain.Prediction, error) {
	return s.repository.GetAllPredictions()
}

// CheckMLHealth checks if ML service is available
func (s *NewsService) CheckMLHealth() error {
	return s.mlClient.HealthCheck()
}
