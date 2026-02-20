package main

import (
	"encoding/base64"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/gin-gonic/gin"
)

type URLInfoRequest struct {
	URL string `json:"url" binding:"required"`
}

type URLInfoResponse struct {
	Success    bool   `json:"success"`
	URL        string `json:"url,omitempty"`
	Title      string `json:"title,omitempty"`
	FaviconURL string `json:"favicon_url,omitempty"`
	Data       string `json:"data,omitempty"`
	MimeType   string `json:"mime_type,omitempty"`
	Error      string `json:"error,omitempty"`
}

type PageInfo struct {
	Title      string
	FaviconURL string
}

func main() {
	r := gin.Default()

	r.POST("/urlInfo", handleURLInfo)

	r.Run(":8081")
}

func handleURLInfo(c *gin.Context) {
	var req URLInfoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, URLInfoResponse{
			Success: false,
			Error:   "缺少url参数",
		})
		return
	}

	targetURL := req.URL
	if !strings.HasPrefix(targetURL, "http://") && !strings.HasPrefix(targetURL, "https://") {
		targetURL = "https://" + targetURL
	}

	parsedURL, err := url.Parse(targetURL)
	if err != nil {
		c.JSON(http.StatusBadRequest, URLInfoResponse{
			Success: false,
			Error:   "无效的URL",
		})
		return
	}

	pageInfo, err := getPageInfo(targetURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, URLInfoResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	faviconURL := pageInfo.FaviconURL
	if faviconURL == "" {
		faviconURL = fmt.Sprintf("%s://%s/favicon.ico", parsedURL.Scheme, parsedURL.Host)
	}

	if !strings.HasPrefix(faviconURL, "http://") && !strings.HasPrefix(faviconURL, "https://") {
		if strings.HasPrefix(faviconURL, "//") {
			faviconURL = parsedURL.Scheme + ":" + faviconURL
		} else if strings.HasPrefix(faviconURL, "/") {
			faviconURL = fmt.Sprintf("%s://%s%s", parsedURL.Scheme, parsedURL.Host, faviconURL)
		} else {
			faviconURL = fmt.Sprintf("%s://%s/%s", parsedURL.Scheme, parsedURL.Host, faviconURL)
		}
	}

	data, mimeType, err := downloadFavicon(faviconURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, URLInfoResponse{
			Success: false,
			Error:   "获取favicon失败: " + err.Error(),
		})
		return
	}

	base64Data := base64.StdEncoding.EncodeToString(data)

	c.JSON(http.StatusOK, URLInfoResponse{
		Success:    true,
		URL:        targetURL,
		Title:      pageInfo.Title,
		FaviconURL: faviconURL,
		Data:       base64Data,
		MimeType:   mimeType,
	})
}

func getPageInfo(targetURL string) (*PageInfo, error) {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return nil
		},
	}

	resp, err := client.Get(targetURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	html := string(body)

	pageInfo := &PageInfo{
		Title:      extractTitleFromHTML(html),
		FaviconURL: extractFaviconFromHTML(html),
	}

	return pageInfo, nil
}

func extractTitleFromHTML(html string) string {
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
			title = strings.TrimSpace(title)
			return title
		}
	}

	return ""
}

func extractFaviconFromHTML(html string) string {
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

		if strings.Contains(linkTag, "rel=\"icon\"") ||
			strings.Contains(linkTag, "rel=\"shortcut icon\"") ||
			strings.Contains(linkTag, "rel='icon'") ||
			strings.Contains(linkTag, "rel='shortcut icon'") ||
			strings.Contains(linkTag, "rel=icon ") ||
			strings.Contains(linkTag, "rel=\"apple-touch-icon\"") ||
			strings.Contains(linkTag, "rel='apple-touch-icon'") {

			hrefStart := strings.Index(linkTag, "href=\"")
			if hrefStart == -1 {
				hrefStart = strings.Index(linkTag, "href='")
				if hrefStart != -1 {
					hrefStart += 6
					hrefEnd := strings.Index(originalTag[hrefStart:], "'")
					if hrefEnd != -1 {
						return originalTag[hrefStart : hrefStart+hrefEnd]
					}
				}
			} else {
				hrefStart += 6
				hrefEnd := strings.Index(originalTag[hrefStart:], "\"")
				if hrefEnd != -1 {
					return originalTag[hrefStart : hrefStart+hrefEnd]
				}
			}
		}

		linkStart = strings.Index(lowerHTML[linkEnd:], "<link")
		if linkStart != -1 {
			linkStart += linkEnd
		}
	}

	return ""
}

func downloadFavicon(faviconURL string) ([]byte, string, error) {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return nil
		},
	}

	resp, err := client.Get(faviconURL)
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
		mimeType = detectMimeType(data)
	}

	return data, mimeType, nil
}

func detectMimeType(data []byte) string {
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
