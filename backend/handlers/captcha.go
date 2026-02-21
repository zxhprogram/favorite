package handlers

import (
	"favicon-service/models"
	"favicon-service/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// CaptchaHandler 验证码处理器
type CaptchaHandler struct {
	service *services.CaptchaService
}

// NewCaptchaHandler 创建验证码处理器
func NewCaptchaHandler() *CaptchaHandler {
	return &CaptchaHandler{
		service: services.NewCaptchaService(),
	}
}

// GetCaptcha 获取验证码
func (h *CaptchaHandler) GetCaptcha(c *gin.Context) {
	h.service.CleanExpired()

	code := h.service.GenerateCode()
	captchaID := h.service.GenerateID()

	imageData, err := h.service.DrawImage(code)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.CaptchaResponse{
			Success: false,
			Error:   "生成验证码失败",
		})
		return
	}

	if err := h.service.Save(captchaID, code); err != nil {
		c.JSON(http.StatusInternalServerError, models.CaptchaResponse{
			Success: false,
			Error:   "保存验证码失败",
		})
		return
	}

	c.JSON(http.StatusOK, models.CaptchaResponse{
		Success:   true,
		CaptchaID: captchaID,
		Image:     imageData,
	})
}
