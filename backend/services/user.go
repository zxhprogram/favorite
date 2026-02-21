package services

import (
	"favicon-service/config"
	"favicon-service/models"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// UserService 用户服务
type UserService struct{}

// NewUserService 创建用户服务
func NewUserService() *UserService {
	return &UserService{}
}

// Create 创建用户
func (s *UserService) Create(email, password, nickname string) error {
	user := &models.User{
		Email:     email,
		Password:  password,
		Nickname:  nickname,
		CreatedAt: time.Now(),
	}
	return config.DB.Create(user).Error
}

// GetByEmail 根据邮箱获取用户
func (s *UserService) GetByEmail(email string) (*models.User, error) {
	var user models.User
	result := config.DB.Where("email = ?", email).First(&user)
	if result.Error != nil {
		return nil, result.Error
	}
	return &user, nil
}

// GetByEmailAndPassword 根据邮箱和密码获取用户
func (s *UserService) GetByEmailAndPassword(email, password string) (*models.User, error) {
	var user models.User
	result := config.DB.Where("email = ? AND password = ?", email, password).First(&user)
	if result.Error != nil {
		return nil, result.Error
	}
	return &user, nil
}

// Exists 检查用户是否存在
func (s *UserService) Exists(email string) bool {
	var user models.User
	result := config.DB.Where("email = ?", email).First(&user)
	return result.Error == nil
}

// UpdateAvatar 更新用户头像
func (s *UserService) UpdateAvatar(email, avatarURL string) error {
	result := config.DB.Model(&models.User{}).Where("email = ?", email).Update("avatar", avatarURL)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return nil
	}
	return nil
}

// GenerateToken 生成JWT令牌
func (s *UserService) GenerateToken(user *models.User) (string, error) {
	claims := jwt.MapClaims{
		"email":    user.Email,
		"nickname": user.Nickname,
		"exp":      time.Now().Add(time.Hour * config.JWTExpireHours).Unix(),
		"iat":      time.Now().Unix(),
		"sub":      user.Email,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(config.JWTSecret))
}
