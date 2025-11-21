package service

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/Naman30903/Final-Year-Project/internal/domain"
)

// ScraperService handles URL scraping
type ScraperService struct {
	httpClient *http.Client
}

// NewScraperService creates a new scraper service
func NewScraperService() *ScraperService {
	return &ScraperService{
		httpClient: &http.Client{
			Timeout: 15 * time.Second,
			CheckRedirect: func(req *http.Request, via []*http.Request) error {
				if len(via) >= 10 {
					return fmt.Errorf("too many redirects")
				}
				return nil
			},
		},
	}
}

// ScrapeURL fetches content from a URL
func (s *ScraperService) ScrapeURL(urlStr string) (string, error) {
	// Validate URL
	if !s.isValidURL(urlStr) {
		return "", domain.ErrInvalidURL
	}

	// Fetch URL
	req, err := http.NewRequest("GET", urlStr, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	// Set user agent to avoid being blocked
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("%w: %v", domain.ErrURLScrapingFailed, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("%w: status code %d", domain.ErrURLScrapingFailed, resp.StatusCode)
	}

	// Read body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("%w: failed to read body", domain.ErrURLScrapingFailed)
	}

	// Basic HTML content extraction (remove tags)
	// TODO: Use a proper HTML parser library like goquery for better extraction
	content := s.extractTextFromHTML(string(body))

	if content == "" {
		return "", fmt.Errorf("%w: no content extracted", domain.ErrURLScrapingFailed)
	}

	return content, nil
}

// isValidURL checks if the URL is valid
func (s *ScraperService) isValidURL(urlStr string) bool {
	u, err := url.Parse(urlStr)
	if err != nil {
		return false
	}

	if u.Scheme != "http" && u.Scheme != "https" {
		return false
	}

	if u.Host == "" {
		return false
	}

	return true
}

// extractTextFromHTML is a basic HTML text extractor
// TODO: Replace with a proper HTML parser for production use
func (s *ScraperService) extractTextFromHTML(html string) string {
	// Very basic implementation - strips HTML tags
	// For production, use: github.com/PuerkitoBio/goquery

	// Remove script and style tags
	html = removeTagsWithContent(html, "script")
	html = removeTagsWithContent(html, "style")

	// Remove HTML tags
	inTag := false
	var result strings.Builder

	for _, char := range html {
		if char == '<' {
			inTag = true
			result.WriteRune(' ')
			continue
		}
		if char == '>' {
			inTag = false
			continue
		}
		if !inTag {
			result.WriteRune(char)
		}
	}

	// Clean up whitespace
	text := result.String()
	text = strings.Join(strings.Fields(text), " ")

	return strings.TrimSpace(text)
}

// removeTagsWithContent removes tags and their content
func removeTagsWithContent(html, tag string) string {
	startTag := fmt.Sprintf("<%s", tag)
	endTag := fmt.Sprintf("</%s>", tag)

	for {
		start := strings.Index(strings.ToLower(html), startTag)
		if start == -1 {
			break
		}

		end := strings.Index(strings.ToLower(html[start:]), endTag)
		if end == -1 {
			break
		}

		html = html[:start] + html[start+end+len(endTag):]
	}

	return html
}
