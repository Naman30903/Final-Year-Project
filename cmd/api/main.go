package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Naman30903/Final-Year-Project/internal/handler"
	"github.com/Naman30903/Final-Year-Project/internal/repository/memory"
	"github.com/Naman30903/Final-Year-Project/internal/service"
)

func main() {
	// Initialize logger
	logger := log.New(os.Stdout, "API: ", log.LstdFlags)

	// Get ML service URL from environment variable
	mlServiceURL := os.Getenv("ML_SERVICE_URL")
	if mlServiceURL == "" {
		mlServiceURL = "http://localhost:8000" // Default for local development
		logger.Printf("ML_SERVICE_URL not set, using default: %s", mlServiceURL)
	}

	// Initialize repositories
	predictionRepo := memory.NewPredictionRepository()

	// Initialize services
	mlClient := service.NewMLClient(mlServiceURL)
	scraperService := service.NewScraperService()
	newsService := service.NewNewsService(mlClient, scraperService, predictionRepo)

	// Initialize handlers
	newsHandler := handler.NewNewsHandler(newsService)

	// Create HTTP server
	srv := &http.Server{
		Addr:         ":8080",
		Handler:      setupRoutes(newsHandler),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		logger.Printf("Starting server on %s", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatalf("Server forced to shutdown: %v", err)
	}

	logger.Println("Server exited")
}

func setupRoutes(newsHandler *handler.NewsHandler) http.Handler {
	mux := http.NewServeMux()

	// Basic health check
	mux.HandleFunc("/health", healthCheckHandler)

	// News analysis endpoints
	mux.HandleFunc("/api/analyze", newsHandler.AnalyzeNews)
	mux.HandleFunc("/api/predictions", newsHandler.GetPrediction)
	mux.HandleFunc("/api/history", newsHandler.GetHistory)
	mux.HandleFunc("/api/health", newsHandler.HealthCheck)

	return mux
}

func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "OK")
}
