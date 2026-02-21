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

	var req models.UpdateAvatarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.UpdateAvatarResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// 更新用户头像
	if err := h.service.UpdateAvatar(userEmail.(string), req.AvatarURL); err != nil {
		c.JSON(http.StatusInternalServerError, models.UpdateAvatarResponse{
			Success: false,
			Error:   "更新头像失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.UpdateAvatarResponse{
		Success: true,
		Avatar:  req.AvatarURL,
		Message: "头像更新成功",
	})
}
