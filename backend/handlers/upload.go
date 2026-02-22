package handlers

import (
	"favicon-service/models"
	"favicon-service/services"

	"github.com/gin-gonic/gin"
)

// UploadHandler 上传处理器
type UploadHandler struct {
	service *services.UploadService
}

// NewUploadHandler 创建上传处理器
func NewUploadHandler() *UploadHandler {
	return &UploadHandler{
		service: services.NewUploadService(),
	}
}

// UploadAvatar 上传头像
func (h *UploadHandler) UploadAvatar(c *gin.Context) models.UploadResponse {
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		return models.UploadResponse{Success: false, Error: "获取文件失败" + err.Error()}
	}
	defer file.Close()

	url, err := h.service.UploadAvatar(file, header)
	if err != nil {
		return models.UploadResponse{
			Success: false,
			Error:   err.Error(),
		}
	}
	return models.UploadResponse{Success: true, URL: url, Message: "上传成功"}
}
