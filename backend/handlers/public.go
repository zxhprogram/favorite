package handlers

import (
	"favicon-service/models"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// PublicHandler 公开数据处理器
type PublicHandler struct{}

// NewPublicHandler 创建公开数据处理器
func NewPublicHandler() *PublicHandler {
	return &PublicHandler{}
}

// GetPublicBookmarks 获取公开书签列表（mock数据）
func (h *PublicHandler) GetPublicBookmarks(c *gin.Context) {
	// Mock数据 - 固定书签列表
	bookmarks := []models.Bookmark{
		{
			ID:          1,
			UserEmail:   "",
			Name:        "HelloGitHub",
			IconURL:     "https://hellogithub.com/favicon/favicon.svg",
			URL:         "https://hellogithub.com",
			Description: "有趣的开源社区，分享GitHub上有趣、入门级的开源项目",
			CreatedAt:   time.Date(2024, 1, 15, 10, 30, 0, 0, time.UTC),
			UpdatedAt:   time.Date(2024, 1, 15, 10, 30, 0, 0, time.UTC),
		},
		{
			ID:          2,
			UserEmail:   "",
			Name:        "GitHub",
			IconURL:     "https://github.com/favicon.ico",
			URL:         "https://github.com",
			Description: "全球最大的代码托管平台，开源协作的首选",
			CreatedAt:   time.Date(2024, 2, 20, 14, 0, 0, 0, time.UTC),
			UpdatedAt:   time.Date(2024, 2, 20, 14, 0, 0, 0, time.UTC),
		},
		{
			ID:          3,
			UserEmail:   "",
			Name:        "Stack Overflow",
			IconURL:     "https://cdn.sstatic.net/Sites/stackoverflow/Img/favicon.ico",
			URL:         "https://stackoverflow.com",
			Description: "程序员问答社区，解决技术难题的宝库",
			CreatedAt:   time.Date(2024, 3, 10, 9, 15, 0, 0, time.UTC),
			UpdatedAt:   time.Date(2024, 3, 10, 9, 15, 0, 0, time.UTC),
		},
		{
			ID:          4,
			UserEmail:   "",
			Name:        "MDN Web Docs",
			IconURL:     "https://developer.mozilla.org/favicon-48x48.png",
			URL:         "https://developer.mozilla.org",
			Description: "Web开发者的权威文档，涵盖HTML、CSS、JavaScript等",
			CreatedAt:   time.Date(2024, 4, 5, 16, 45, 0, 0, time.UTC),
			UpdatedAt:   time.Date(2024, 4, 5, 16, 45, 0, 0, time.UTC),
		},
		{
			ID:          5,
			UserEmail:   "",
			Name:        "Go语言官方",
			IconURL:     "https://go.dev/favicon.ico",
			URL:         "https://go.dev",
			Description: "Go编程语言官方网站，学习Go语言的最佳起点",
			CreatedAt:   time.Date(2024, 5, 12, 11, 20, 0, 0, time.UTC),
			UpdatedAt:   time.Date(2024, 5, 12, 11, 20, 0, 0, time.UTC),
		},
	}

	c.JSON(http.StatusOK, models.BookmarkResponse{
		Success:   true,
		Bookmarks: bookmarks,
	})
}
