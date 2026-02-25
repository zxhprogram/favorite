package handlers

import (
	"encoding/json"
	"favicon-service/models"
	"favicon-service/services"
	"io"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type FolderHandler struct {
	service *services.FolderService
}

func NewFolderHandler() *FolderHandler {
	return &FolderHandler{
		service: services.NewFolderService(),
	}
}

func (h *FolderHandler) Create(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.FolderResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	var req models.CreateFolderRequest
	b, _ := io.ReadAll(c.Request.Body)
	if err := json.Unmarshal(b, &req); err != nil {
		c.JSON(http.StatusBadRequest, models.FolderResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	folder, err := h.service.Create(userEmail.(string), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.FolderResponse{
			Success: false,
			Error:   "创建文件夹失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.FolderResponse{
		Success: true,
		Folder:  folder,
		Message: "文件夹创建成功",
	})
}

func (h *FolderHandler) GetAll(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.FolderResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	folders, err := h.service.GetAllByUser(userEmail.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.FolderResponse{
			Success: false,
			Error:   "获取文件夹列表失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.FolderResponse{
		Success: true,
		Folders: folders,
	})
}

func (h *FolderHandler) GetByID(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.FolderResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.FolderResponse{
			Success: false,
			Error:   "无效的文件夹ID",
		})
		return
	}

	folder, err := h.service.GetByID(uint(id), userEmail.(string))
	if err != nil {
		c.JSON(http.StatusNotFound, models.FolderResponse{
			Success: false,
			Error:   "文件夹不存在",
		})
		return
	}

	c.JSON(http.StatusOK, models.FolderResponse{
		Success: true,
		Folder:  folder,
	})
}

func (h *FolderHandler) Update(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.FolderResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.FolderResponse{
			Success: false,
			Error:   "无效的文件夹ID",
		})
		return
	}

	var req models.UpdateFolderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.FolderResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	folder, err := h.service.Update(uint(id), userEmail.(string), &req)
	if err != nil {
		c.JSON(http.StatusNotFound, models.FolderResponse{
			Success: false,
			Error:   "文件夹不存在或更新失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.FolderResponse{
		Success: true,
		Folder:  folder,
		Message: "文件夹更新成功",
	})
}

func (h *FolderHandler) Delete(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.FolderResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.FolderResponse{
			Success: false,
			Error:   "无效的文件夹ID",
		})
		return
	}

	if err := h.service.Delete(uint(id), userEmail.(string)); err != nil {
		c.JSON(http.StatusNotFound, models.FolderResponse{
			Success: false,
			Error:   "文件夹不存在或删除失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.FolderResponse{
		Success: true,
		Message: "文件夹删除成功",
	})
}

func (h *FolderHandler) MoveBookmark(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.FolderResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	var req models.MoveBookmarkToFolderRequest
	b, _ := io.ReadAll(c.Request.Body)
	if err := json.Unmarshal(b, &req); err != nil {
		c.JSON(http.StatusBadRequest, models.FolderResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	if err := h.service.MoveBookmarkToFolder(userEmail.(string), &req); err != nil {
		c.JSON(http.StatusInternalServerError, models.FolderResponse{
			Success: false,
			Error:   "移动书签失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.FolderResponse{
		Success: true,
		Message: "书签移动成功",
	})
}

func (h *FolderHandler) GetBookmarksInFolder(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.FolderResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.FolderResponse{
			Success: false,
			Error:   "无效的文件夹ID",
		})
		return
	}

	bookmarks, err := h.service.GetBookmarksInFolder(uint(id), userEmail.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.BookmarkResponse{
			Success: false,
			Error:   "获取文件夹内书签失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.BookmarkResponse{
		Success:   true,
		Bookmarks: bookmarks,
	})
}
