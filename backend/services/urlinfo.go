package services

import (
	"favicon-service/config"
	"favicon-service/models"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
)

// URLInfoService URL信息服务
type URLInfoService struct{}

// NewURLInfoService 创建URL信息服务
func NewURLInfoService() *URLInfoService {
	return &URLInfoService{}
}

// GetPageInfo 获取页面信息
func (s *URLInfoService) GetPageInfo(targetURL string) (*models.PageInfo, error) {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return nil
		},
	}

	req, err := http.NewRequest("GET", targetURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", config.ChromeUserAgent)

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	html := string(body)

	return &models.PageInfo{
		Title:      s.extractTitle(html),
		FaviconURL: s.extractFavicon(html),
	}, nil
}

// DownloadFavicon 下载favicon
func (s *URLInfoService) DownloadFavicon(faviconURL string) ([]byte, string, error) {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return nil
		},
	}

	req, err := http.NewRequest("GET", faviconURL, nil)
	if err != nil {
		return nil, "", err
	}
	req.Header.Set("User-Agent", config.ChromeUserAgent)

	resp, err := client.Do(req)
	if err != nil {
		return nil, "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, "", fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, "", err
	}

	mimeType := resp.Header.Get("Content-Type")
	if mimeType == "" {
		mimeType = s.detectMimeType(data)
	}

	return data, mimeType, nil
}

// ResolveFaviconURL 解析favicon完整URL
func (s *URLInfoService) ResolveFaviconURL(baseURL *url.URL, faviconURL string) string {
	if faviconURL == "" {
		return fmt.Sprintf("%s://%s/favicon.ico", baseURL.Scheme, baseURL.Host)
	}

	if strings.HasPrefix(faviconURL, "http://") || strings.HasPrefix(faviconURL, "https://") {
		return faviconURL
	}

	if strings.HasPrefix(faviconURL, "//") {
		return baseURL.Scheme + ":" + faviconURL
	}

	if strings.HasPrefix(faviconURL, "/") {
		return fmt.Sprintf("%s://%s%s", baseURL.Scheme, baseURL.Host, faviconURL)
	}

	return fmt.Sprintf("%s://%s/%s", baseURL.Scheme, baseURL.Host, faviconURL)
}

// extractTitle 从HTML中提取标题
func (s *URLInfoService) extractTitle(html string) string {
	lowerHTML := strings.ToLower(html)

	titleStart := strings.Index(lowerHTML, "<title>")
	if titleStart == -1 {
		titleStart = strings.Index(lowerHTML, "<title ")
	}

	if titleStart != -1 {
		titleStart = strings.Index(html[titleStart:], ">") + titleStart + 1
		titleEnd := strings.Index(lowerHTML[titleStart:], "</title>")

		if titleEnd != -1 {
			title := html[titleStart : titleStart+titleEnd]
			return strings.TrimSpace(title)
		}
	}

	return ""
}

// extractFavicon 从HTML中提取favicon
func (s *URLInfoService) extractFavicon(html string) string {
	lowerHTML := strings.ToLower(html)

	linkStart := strings.Index(lowerHTML, "<link")
	for linkStart != -1 {
		linkEnd := strings.Index(lowerHTML[linkStart:], ">")
		if linkEnd == -1 {
			break
		}
		linkEnd += linkStart

		linkTag := lowerHTML[linkStart:linkEnd]
		originalTag := html[linkStart:linkEnd]

		if s.isFaviconLink(linkTag) {
			href := s.extractHref(originalTag, linkTag)
			if href != "" {
				return href
			}
		}

		linkStart = strings.Index(lowerHTML[linkEnd:], "<link")
		if linkStart != -1 {
			linkStart += linkEnd
		}
	}

	return ""
}

// isFaviconLink 判断是否为favicon链接
func (s *URLInfoService) isFaviconLink(linkTag string) bool {
	return strings.Contains(linkTag, "rel=\"icon\"") ||
		strings.Contains(linkTag, "rel=\"shortcut icon\"") ||
		strings.Contains(linkTag, "rel='icon'") ||
		strings.Contains(linkTag, "rel='shortcut icon'") ||
		strings.Contains(linkTag, "rel=icon ") ||
		strings.Contains(linkTag, "rel=\"apple-touch-icon\"") ||
		strings.Contains(linkTag, "rel='apple-touch-icon'")
}

// extractHref 提取href属性
func (s *URLInfoService) extractHref(originalTag, lowerTag string) string {
	hrefStart := strings.Index(lowerTag, "href=\"")
	if hrefStart != -1 {
		hrefStart += 6
		hrefEnd := strings.Index(originalTag[hrefStart:], "\"")
		if hrefEnd != -1 {
			return originalTag[hrefStart : hrefStart+hrefEnd]
		}
	}

	hrefStart = strings.Index(lowerTag, "href='")
	if hrefStart != -1 {
		hrefStart += 6
		hrefEnd := strings.Index(originalTag[hrefStart:], "'")
		if hrefEnd != -1 {
			return originalTag[hrefStart : hrefStart+hrefEnd]
		}
	}

	return ""
}

// detectMimeType 检测MIME类型
func (s *URLInfoService) detectMimeType(data []byte) string {
	if len(data) < 4 {
		return "application/octet-stream"
	}

	if data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
		return "image/png"
	}
	if data[0] == 0xFF && data[1] == 0xD8 {
		return "image/jpeg"
	}
	if data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 {
		return "image/gif"
	}
	if data[0] == 0x00 && data[1] == 0x00 && data[2] == 0x01 && data[3] == 0x00 {
		return "image/x-icon"
	}
	if data[0] == 0x3C && (data[1] == 0x3F || data[1] == 0x73) {
		return "image/svg+xml"
	}

	return "application/octet-stream"
}
