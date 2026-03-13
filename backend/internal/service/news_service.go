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

// AnalyzeNews analyzes news article or URL for fake news detection.
//
// For URL requests the flow is:
//  1. Go scraper extracts article text + metadata locally.
//  2. Extracted text is sent to the ML service POST /predict.
//  3. If Go scraping fails, fall back to ML service POST /predict/url
//     (the Python service has its own scraper).
func (s *NewsService) AnalyzeNews(req *domain.AnalysisRequest) (*domain.Prediction, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}

	var prediction *domain.Prediction
	var err error

	switch req.Type {
	case "text":
		prediction, err = s.mlClient.Predict(req.Content)
		if err != nil {
			return nil, err
		}

	case "url":
		prediction, err = s.analyzeURL(req.Content)
		if err != nil {
			return nil, err
		}

	default:
		return nil, domain.ErrInvalidRequestType
	}

	// Enrich with request metadata.
	prediction.ID = uuid.New().String()
	prediction.RequestType = req.Type
	prediction.OriginalContent = req.Content
	prediction.CreatedAt = time.Now()

	// Persist (best-effort).
	if saveErr := s.repository.SavePrediction(prediction); saveErr != nil {
		fmt.Printf("Warning: failed to save prediction: %v\n", saveErr)
	}

	return prediction, nil
}

// analyzeURL tries the Go scraper first, then falls back to the ML service's
// own /predict/url endpoint.
func (s *NewsService) analyzeURL(articleURL string) (*domain.Prediction, error) {
	// ── primary: scrape locally then send text ──
	scrapeResult, scrapeErr := s.scraper.ScrapeArticle(articleURL)
	if scrapeErr == nil {
		prediction, err := s.mlClient.Predict(scrapeResult.Text)
		if err != nil {
			return nil, err
		}
		// Attach metadata from the scraper.
		prediction.ArticleTitle = scrapeResult.Title
		prediction.ArticleDescription = scrapeResult.Description
		prediction.ArticleAuthor = scrapeResult.Author
		prediction.ArticleSource = scrapeResult.Source
		return prediction, nil
	}

	// ── fallback: let the ML service scrape ──
	fmt.Printf("Go scraper failed (%v), falling back to ML /predict/url\n", scrapeErr)
	prediction, err := s.mlClient.PredictURL(articleURL)
	if err != nil {
		// Return the original scrape error — it's more descriptive.
		return nil, fmt.Errorf("%w (ML fallback also failed: %v)", scrapeErr, err)
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
