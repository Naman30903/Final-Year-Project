package domain

import "time"

// NewsArticle represents a news article to be analyzed
type NewsArticle struct {
	ID          string    `json:"id"`
	Content     string    `json:"content"`     // The text content of the article
	URL         string    `json:"url"`         // Original URL if scraped
	Title       string    `json:"title"`       // Article title
	Source      string    `json:"source"`      // Source of the article
	CreatedAt   time.Time `json:"created_at"`
}

// AnalysisRequest represents a request to analyze news
type AnalysisRequest struct {
	Type    string `json:"type"`    // "text" or "url"
	Content string `json:"content"` // Text content or URL
}

// Validate validates the analysis request
func (r *AnalysisRequest) Validate() error {
	if r.Type != "text" && r.Type != "url" {
		return ErrInvalidRequestType
	}
	if r.Content == "" {
		return ErrEmptyContent
	}
	return nil
}
