package handlers

import (
	"encoding/json"
	"favicon-service/models"
	"favicon-service/services"
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
)

// BookmarkHandler 书签处理器
type BookmarkHandler struct {
	service *services.BookmarkService
}

// NewBookmarkHandler 创建书签处理器
func NewBookmarkHandler() *BookmarkHandler {
	return &BookmarkHandler{
		service: services.NewBookmarkService(),
	}
}

// Create 创建书签
func (h *BookmarkHandler) Create(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.BookmarkResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}
	var body = c.Request.Body
	b, _ := io.ReadAll(body)
	var sss = string(b)

	var req models.CreateBookmarkRequest
	err := json.Unmarshal([]byte(sss), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.BookmarkResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// 如果没有提供IconMimeType，尝试获取
	//if req.IconMimeType == "" && req.IconURL != "" {
	//	_, mimeType, err := h.urlInfoService.DownloadFavicon(req.IconURL)
	//	if err == nil {
	//		req.IconMimeType = mimeType
	//	}
	//}

	bookmark, err := h.service.Create(userEmail.(string), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.BookmarkResponse{
			Success: false,
			Error:   "创建书签失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.BookmarkResponse{
		Success:  true,
		Bookmark: bookmark,
		Message:  "书签创建成功",
	})
}

// GetAll 获取所有书签
func (h *BookmarkHandler) GetAll(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.BookmarkResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	bookmarks, err := h.service.GetAllByUser(userEmail.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.BookmarkResponse{
			Success: false,
			Error:   "获取书签列表失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.BookmarkResponse{
		Success:   true,
		Bookmarks: bookmarks,
	})
}

// GetByID 根据ID获取书签
func (h *BookmarkHandler) GetByID(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.BookmarkResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.BookmarkResponse{
			Success: false,
			Error:   "无效的书签ID",
		})
		return
	}

	bookmark, err := h.service.GetByID(uint(id), userEmail.(string))
	if err != nil {
		c.JSON(http.StatusNotFound, models.BookmarkResponse{
			Success: false,
			Error:   "书签不存在",
		})
		return
	}

	c.JSON(http.StatusOK, models.BookmarkResponse{
		Success:  true,
		Bookmark: bookmark,
	})
}

// Update 更新书签
func (h *BookmarkHandler) Update(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.BookmarkResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.BookmarkResponse{
			Success: false,
			Error:   "无效的书签ID",
		})
		return
	}

	var req models.UpdateBookmarkRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.BookmarkResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// 自动补全URL协议前缀
	if !strings.HasPrefix(req.URL, "http://") && !strings.HasPrefix(req.URL, "https://") {
		req.URL = "https://" + req.URL
	}

	// 如果没有提供IconMimeType，尝试获取
	//if req.IconMimeType == "" && req.IconURL != "" {
	//	_, mimeType, err := h.urlInfoService.DownloadFavicon(req.IconURL)
	//	if err == nil {
	//		req.IconMimeType = mimeType
	//	}
	//}

	bookmark, err := h.service.Update(uint(id), userEmail.(string), &req)
	if err != nil {
		c.JSON(http.StatusNotFound, models.BookmarkResponse{
			Success: false,
			Error:   "书签不存在或更新失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.BookmarkResponse{
		Success:  true,
		Bookmark: bookmark,
		Message:  "书签更新成功",
	})
}

// Delete 删除书签
func (h *BookmarkHandler) Delete(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.BookmarkResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.BookmarkResponse{
			Success: false,
			Error:   "无效的书签ID",
		})
		return
	}

	if err := h.service.Delete(uint(id), userEmail.(string)); err != nil {
		c.JSON(http.StatusNotFound, models.BookmarkResponse{
			Success: false,
			Error:   "书签不存在或删除失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.BookmarkResponse{
		Success: true,
		Message: "书签删除成功",
	})
}
