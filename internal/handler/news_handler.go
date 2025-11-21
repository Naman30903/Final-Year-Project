package handler

import (
	"encoding/json"
	"net/http"

	"github.com/Naman30903/Final-Year-Project/internal/domain"
	"github.com/Naman30903/Final-Year-Project/internal/service"
)

// NewsHandler handles news analysis HTTP requests
type NewsHandler struct {
	newsService *service.NewsService
}

// NewNewsHandler creates a new news handler
func NewNewsHandler(newsService *service.NewsService) *NewsHandler {
	return &NewsHandler{
		newsService: newsService,
	}
}

// AnalyzeNews handles POST /api/analyze
func (h *NewsHandler) AnalyzeNews(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse request
	var req domain.AnalysisRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Analyze news
	prediction, err := h.newsService.AnalyzeNews(&req)
	if err != nil {
		// Handle specific errors
		switch err {
		case domain.ErrInvalidRequestType, domain.ErrEmptyContent, domain.ErrInvalidURL:
			respondWithError(w, http.StatusBadRequest, err.Error())
		case domain.ErrURLScrapingFailed:
			respondWithError(w, http.StatusBadGateway, "Failed to scrape URL content")
		case domain.ErrMLServiceUnavailable, domain.ErrPredictionFailed:
			respondWithError(w, http.StatusServiceUnavailable, "ML service unavailable")
		default:
			respondWithError(w, http.StatusInternalServerError, "Internal server error")
		}
		return
	}

	// Send response
	respondWithJSON(w, http.StatusOK, domain.PredictionResponse{
		Success:    true,
		Prediction: prediction,
	})
}

// GetPrediction handles GET /api/predictions/{id}
func (h *NewsHandler) GetPrediction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract ID from URL path
	// For now, using query parameter. Use a router like gorilla/mux for path params
	id := r.URL.Query().Get("id")
	if id == "" {
		respondWithError(w, http.StatusBadRequest, "prediction ID is required")
		return
	}

	// Get prediction
	prediction, err := h.newsService.GetPrediction(id)
	if err != nil {
		respondWithError(w, http.StatusNotFound, "Prediction not found")
		return
	}

	respondWithJSON(w, http.StatusOK, prediction)
}

// GetHistory handles GET /api/history
func (h *NewsHandler) GetHistory(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get all predictions
	predictions, err := h.newsService.GetHistory()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Failed to retrieve history")
		return
	}

	respondWithJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"count":   len(predictions),
		"history": predictions,
	})
}

// HealthCheck handles GET /api/health
func (h *NewsHandler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Check ML service health
	err := h.newsService.CheckMLHealth()

	status := "healthy"
	mlServiceStatus := "up"

	if err != nil {
		status = "degraded"
		mlServiceStatus = "down"
	}

	respondWithJSON(w, http.StatusOK, map[string]interface{}{
		"status":     status,
		"ml_service": mlServiceStatus,
	})
}

// Helper functions

func respondWithJSON(w http.ResponseWriter, statusCode int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(payload)
}

func respondWithError(w http.ResponseWriter, statusCode int, message string) {
	respondWithJSON(w, statusCode, map[string]string{
		"error": message,
	})
}
