package handlers

import (
	"favicon-service/models"
	"favicon-service/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// UserHandler 用户处理器
type UserHandler struct {
	service *services.UserService
}

// NewUserHandler 创建用户处理器
func NewUserHandler() *UserHandler {
	return &UserHandler{
		service: services.NewUserService(),
	}
}

var uploadHandler = NewUploadHandler()

// UpdateAvatar 更新头像
func (h *UserHandler) UpdateAvatar(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.UpdateAvatarResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}
	var res = uploadHandler.UploadAvatar(c)
	// 更新用户头像
	if err := h.service.UpdateAvatar(userEmail.(string), res.URL); err != nil {
		c.JSON(http.StatusInternalServerError, models.UpdateAvatarResponse{
			Success: false,
			Error:   "更新头像失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.UpdateAvatarResponse{
		Success: true,
		Avatar:  res.URL,
		Message: "头像更新成功",
	})
}
