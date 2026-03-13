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

// blockedDomains lists hosts that block automated scraping and return garbage.
var blockedDomains = []string{
	"twitter.com", "x.com",
	"instagram.com", "facebook.com", "fb.com",
	"tiktok.com", "linkedin.com",
	"youtube.com", "youtu.be",
}

// ScraperService handles URL scraping with best-practice article extraction.
type ScraperService struct {
	httpClient *http.Client
}

// ScrapeResult contains extracted article data.
type ScrapeResult struct {
	Text        string // cleaned article body
	Title       string
	Description string
	Author      string
	Source      string // hostname
}

// NewScraperService creates a new scraper service.
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

// ScrapeURL fetches a URL and returns extracted article content.
// Kept for backward-compat — returns only the body text.
func (s *ScraperService) ScrapeURL(urlStr string) (string, error) {
	res, err := s.ScrapeArticle(urlStr)
	if err != nil {
		return "", err
	}
	return res.Text, nil
}

// ScrapeArticle fetches a URL and returns structured article data.
func (s *ScraperService) ScrapeArticle(urlStr string) (*ScrapeResult, error) {
	// ---------- validate ----------
	parsed, err := s.validateURL(urlStr)
	if err != nil {
		return nil, err
	}

	// ---------- blocked domains ----------
	host := strings.ToLower(parsed.Hostname())
	for _, blocked := range blockedDomains {
		if host == blocked || strings.HasSuffix(host, "."+blocked) {
			return nil, fmt.Errorf("%w: %s blocks automated scraping — paste the article text instead",
				domain.ErrURLScrapingFailed, host)
		}
	}

	// ---------- fetch ----------
	req, err := http.NewRequest("GET", urlStr, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "+
			"(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
	req.Header.Set("Accept", "text/html,application/xhtml+xml")
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", domain.ErrURLScrapingFailed, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("%w: HTTP %d from %s",
			domain.ErrURLScrapingFailed, resp.StatusCode, host)
	}

	ct := resp.Header.Get("Content-Type")
	if ct != "" && !strings.Contains(ct, "html") {
		return nil, fmt.Errorf("%w: expected HTML, got %s", domain.ErrURLScrapingFailed, ct)
	}

	// ---------- parse ----------
	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", domain.ErrURLScrapingFailed, err)
	}

	result := &ScrapeResult{Source: host}

	// Extract metadata first (before removing elements).
	result.Title, result.Description, result.Author = extractMeta(doc)

	// Remove noise.
	doc.Find("script, style, nav, header, footer, aside, form, iframe, " +
		"noscript, svg, button, [role='navigation'], [role='banner'], " +
		"[role='complementary'], .sidebar, .comments, .social-share, " +
		".newsletter-signup, .ad, .advertisement, #comments").Remove()

	// Extract body.
	result.Text = extractArticleBody(doc)

	if len(result.Text) < 80 {
		return nil, fmt.Errorf(
			"%w: extracted only %d chars from %s — the site may require JavaScript rendering",
			domain.ErrURLScrapingFailed, len(result.Text), host)
	}

	return result, nil
}

// ---------- private helpers ----------

func (s *ScraperService) validateURL(urlStr string) (*url.URL, error) {
	u, err := url.Parse(urlStr)
	if err != nil {
		return nil, domain.ErrInvalidURL
	}
	if u.Scheme != "http" && u.Scheme != "https" {
		return nil, fmt.Errorf("%w: scheme must be http or https", domain.ErrInvalidURL)
	}
	if u.Host == "" {
		return nil, fmt.Errorf("%w: missing host", domain.ErrInvalidURL)
	}
	return u, nil
}

// extractMeta pulls title, description, and author from <head> metadata.
func extractMeta(doc *goquery.Document) (title, description, author string) {
	// Title: og:title → <title>
	if t, ok := doc.Find(`meta[property="og:title"]`).Attr("content"); ok && t != "" {
		title = t
	} else {
		title = strings.TrimSpace(doc.Find("title").First().Text())
	}

	// Description: og:description → meta description
	if d, ok := doc.Find(`meta[property="og:description"]`).Attr("content"); ok && d != "" {
		description = d
	} else if d, ok = doc.Find(`meta[name="description"]`).Attr("content"); ok {
		description = d
	}

	// Author: meta author → article:author → .author class
	if a, ok := doc.Find(`meta[name="author"]`).Attr("content"); ok && a != "" {
		author = a
	} else if a, ok = doc.Find(`meta[property="article:author"]`).Attr("content"); ok && a != "" {
		author = a
	} else {
		author = strings.TrimSpace(doc.Find(".author, [rel='author']").First().Text())
	}

	return
}

// extractArticleBody applies a priority cascade to pull the article body text.
func extractArticleBody(doc *goquery.Document) string {
	// ── Strategy 1: <article> tag ──
	if article := doc.Find("article"); article.Length() > 0 {
		if text := paragraphsFrom(article); len(text) > 200 {
			return text
		}
	}

	// ── Strategy 2: scored containers ──
	// Find the <div>/<section> with the highest paragraph density.
	type scored struct {
		node  *goquery.Selection
		score int
	}
	var best scored
	doc.Find("div, section").Each(func(_ int, sel *goquery.Selection) {
		score := 0
		sel.Find("p").Each(func(_ int, p *goquery.Selection) {
			t := strings.TrimSpace(p.Text())
			if len(t) > 40 {
				score += len(t) // weight by character count
			}
		})
		if score > best.score {
			best = scored{node: sel, score: score}
		}
	})
	if best.node != nil && best.score > 300 {
		if text := paragraphsFrom(best.node); len(text) > 200 {
			return text
		}
	}

	// ── Strategy 3: common CSS selectors ──
	selectors := []string{
		"[role='main']",
		".article-content", ".post-content", ".entry-content",
		".story-body", ".article-body", ".article__body",
		"main", "#content", ".content",
	}
	for _, sel := range selectors {
		node := doc.Find(sel)
		if node.Length() == 0 {
			continue
		}
		if text := paragraphsFrom(node); len(text) > 200 {
			return text
		}
	}

	// ── Strategy 4: all <p> fallback ──
	return paragraphsFrom(doc.Selection)
}

// paragraphsFrom concatenates meaningful <p> text within a container.
func paragraphsFrom(sel *goquery.Selection) string {
	var parts []string
	sel.Find("p").Each(func(_ int, p *goquery.Selection) {
		t := strings.TrimSpace(p.Text())
		if len(t) > 40 {
			parts = append(parts, t)
		}
	})
	text := strings.Join(parts, " ")
	return strings.Join(strings.Fields(text), " ") // normalize whitespace
}

// isValidURL is kept for any external callers.
func (s *ScraperService) isValidURL(urlStr string) bool {
	_, err := s.validateURL(urlStr)
	return err == nil
}

// extractMetadata kept for backward compat.
func (s *ScraperService) extractMetadata(body io.Reader) (title, description, author string, err error) {
	doc, err := goquery.NewDocumentFromReader(body)
	if err != nil {
		return "", "", "", err
	}
	title, description, author = extractMeta(doc)
	return
}
