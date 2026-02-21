package handlers

import (
	"favicon-service/models"
	"favicon-service/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// AuthHandler 认证处理器
type AuthHandler struct {
	userService    *services.UserService
	captchaService *services.CaptchaService
}

// NewAuthHandler 创建认证处理器
func NewAuthHandler() *AuthHandler {
	return &AuthHandler{
		userService:    services.NewUserService(),
		captchaService: services.NewCaptchaService(),
	}
}

// Register 用户注册
func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.AuthResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// 验证验证码
	if !h.captchaService.Verify(req.CaptchaID, req.CaptchaCode) {
		c.JSON(http.StatusBadRequest, models.AuthResponse{
			Success: false,
			Error:   "验证码错误或已过期",
		})
		return
	}

	// 检查用户是否已存在
	if h.userService.Exists(req.Email) {
		c.JSON(http.StatusConflict, models.AuthResponse{
			Success: false,
			Error:   "该邮箱已被注册",
		})
		return
	}

	// 创建用户
	if err := h.userService.Create(req.Email, req.Password, req.Nickname); err != nil {
		c.JSON(http.StatusInternalServerError, models.AuthResponse{
			Success: false,
			Error:   "注册失败",
		})
		return
	}

	// 清除已使用的验证码
	h.captchaService.Clear(req.CaptchaID)

	c.JSON(http.StatusOK, models.AuthResponse{
		Success: true,
		Message: "注册成功",
	})
}

// Login 用户登录
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.AuthResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// 验证验证码
	if !h.captchaService.Verify(req.CaptchaID, req.CaptchaCode) {
		c.JSON(http.StatusBadRequest, models.AuthResponse{
			Success: false,
			Error:   "验证码错误或已过期",
		})
		return
	}

	// 验证用户凭据
	user, err := h.userService.GetByEmailAndPassword(req.Email, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.AuthResponse{
			Success: false,
			Error:   "邮箱或密码错误",
		})
		return
	}

	// 生成JWT令牌
	token, err := h.userService.GenerateToken(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.AuthResponse{
			Success: false,
			Error:   "生成Token失败",
		})
		return
	}

	// 清除已使用的验证码
	h.captchaService.Clear(req.CaptchaID)

	c.JSON(http.StatusOK, models.AuthResponse{
		Success:  true,
		Token:    token,
		Nickname: user.Nickname,
		Avatar:   user.Avatar,
		Message:  "登录成功",
	})
}
