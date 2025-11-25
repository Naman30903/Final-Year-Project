package memory

import (
	"fmt"
	"sync"

	"github.com/Naman30903/Final-Year-Project/internal/domain"
)

// PredictionRepository implements in-memory storage for predictions
type PredictionRepository struct {
	predictions map[string]*domain.Prediction
	mu          sync.RWMutex
}

// NewPredictionRepository creates a new in-memory prediction repository
func NewPredictionRepository() *PredictionRepository {
	return &PredictionRepository{
		predictions: make(map[string]*domain.Prediction),
	}
}

// SavePrediction saves a prediction to memory
func (r *PredictionRepository) SavePrediction(prediction *domain.Prediction) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if prediction.ID == "" {
		return fmt.Errorf("prediction ID cannot be empty")
	}

	r.predictions[prediction.ID] = prediction
	return nil
}

// GetPredictionByID retrieves a prediction by ID
func (r *PredictionRepository) GetPredictionByID(id string) (*domain.Prediction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	prediction, exists := r.predictions[id]
	if !exists {
		return nil, fmt.Errorf("prediction not found with id: %s", id)
	}

	return prediction, nil
}

// GetAllPredictions retrieves all predictions
func (r *PredictionRepository) GetAllPredictions() ([]*domain.Prediction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	predictions := make([]*domain.Prediction, 0, len(r.predictions))
	for _, p := range r.predictions {
		predictions = append(predictions, p)
	}

	return predictions, nil
}

// DeletePrediction deletes a prediction by ID
func (r *PredictionRepository) DeletePrediction(id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.predictions[id]; !exists {
		return fmt.Errorf("prediction not found with id: %s", id)
	}

	delete(r.predictions, id)
	return nil
}

// Clear removes all predictions (useful for testing)
func (r *PredictionRepository) Clear() {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.predictions = make(map[string]*domain.Prediction)
}
