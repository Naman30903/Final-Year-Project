package service

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/Naman30903/Final-Year-Project/internal/domain"
	"github.com/PuerkitoBio/goquery"
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
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("%w: %v", domain.ErrURLScrapingFailed, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("%w: status code %d", domain.ErrURLScrapingFailed, resp.StatusCode)
	}

	// Parse HTML using goquery
	content, err := s.extractContentWithGoquery(resp.Body)
	if err != nil {
		return "", fmt.Errorf("%w: %v", domain.ErrURLScrapingFailed, err)
	}

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

// extractContentWithGoquery extracts article content using goquery
func (s *ScraperService) extractContentWithGoquery(body io.Reader) (string, error) {
	doc, err := goquery.NewDocumentFromReader(body)
	if err != nil {
		return "", err
	}

	// Remove unwanted elements
	doc.Find("script, style, nav, header, footer, aside, form, iframe, noscript").Remove()

	var content strings.Builder

	// Try to find article content using common selectors
	// Priority order: article-specific selectors first, then fallbacks
	articleSelectors := []string{
		"article",
		"[role='main']",
		".article-content",
		".post-content",
		".entry-content",
		".content",
		"main",
		"#content",
		".story-body",
		".article-body",
	}

	foundContent := false
	for _, selector := range articleSelectors {
		doc.Find(selector).Each(func(i int, s *goquery.Selection) {
			// Extract text from paragraphs, headings, and list items
			s.Find("p, h1, h2, h3, h4, h5, h6, li").Each(func(j int, elem *goquery.Selection) {
				text := strings.TrimSpace(elem.Text())
				if text != "" {
					content.WriteString(text)
					content.WriteString(" ")
					foundContent = true
				}
			})
		})

		if foundContent {
			break
		}
	}

	// Fallback: if no content found with selectors, extract all paragraphs
	if !foundContent {
		doc.Find("p").Each(func(i int, s *goquery.Selection) {
			text := strings.TrimSpace(s.Text())
			if text != "" && len(text) > 50 { // Filter out very short paragraphs
				content.WriteString(text)
				content.WriteString(" ")
			}
		})
	}

	// Clean up and normalize whitespace
	result := strings.Join(strings.Fields(content.String()), " ")
	return strings.TrimSpace(result), nil
}

// extractMetadata extracts metadata from the HTML document (optional)
func (s *ScraperService) extractMetadata(body io.Reader) (title, description, author string, err error) {
	doc, err := goquery.NewDocumentFromReader(body)
	if err != nil {
		return "", "", "", err
	}

	// Extract title
	title = doc.Find("title").First().Text()
	if title == "" {
		title, _ = doc.Find("meta[property='og:title']").Attr("content")
	}

	// Extract description
	description, _ = doc.Find("meta[name='description']").Attr("content")
	if description == "" {
		description, _ = doc.Find("meta[property='og:description']").Attr("content")
	}

	// Extract author
	author, _ = doc.Find("meta[name='author']").Attr("content")
	if author == "" {
		author, _ = doc.Find("meta[property='article:author']").Attr("content")
	}

	return strings.TrimSpace(title), strings.TrimSpace(description), strings.TrimSpace(author), nil
}
