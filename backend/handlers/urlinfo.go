package handlers

import (
	"encoding/base64"
	"favicon-service/models"
	"favicon-service/services"
	"net/http"
	"net/url"
	"strings"

	"github.com/gin-gonic/gin"
)

// URLInfoHandler URL信息处理器
type URLInfoHandler struct {
	service *services.URLInfoService
}

// NewURLInfoHandler 创建URL信息处理器
func NewURLInfoHandler() *URLInfoHandler {
	return &URLInfoHandler{
		service: services.NewURLInfoService(),
	}
}

// GetURLInfo 获取URL信息
func (h *URLInfoHandler) GetURLInfo(c *gin.Context) {
	var req models.URLInfoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.URLInfoResponse{
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
		c.JSON(http.StatusBadRequest, models.URLInfoResponse{
			Success: false,
			Error:   "无效的URL",
		})
		return
	}

	pageInfo, err := h.service.GetPageInfo(targetURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.URLInfoResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	faviconURL := h.service.ResolveFaviconURL(parsedURL, pageInfo.FaviconURL)

	data, mimeType, err := h.service.DownloadFavicon(faviconURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.URLInfoResponse{
			Success: false,
			Error:   "获取favicon失败: " + err.Error(),
		})
		return
	}

	base64Data := base64.StdEncoding.EncodeToString(data)

	c.JSON(http.StatusOK, models.URLInfoResponse{
		Success:    true,
		URL:        targetURL,
		Title:      pageInfo.Title,
		FaviconURL: faviconURL,
		Data:       base64Data,
		MimeType:   mimeType,
	})
}
