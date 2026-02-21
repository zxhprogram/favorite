package services

import (
	"bytes"
	"encoding/base64"
	"favicon-service/config"
	"favicon-service/models"
	"fmt"
	"math/rand"
	"time"

	"github.com/fogleman/gg"
)

// CaptchaService 验证码服务
type CaptchaService struct{}

// NewCaptchaService 创建验证码服务
func NewCaptchaService() *CaptchaService {
	return &CaptchaService{}
}

// GenerateCode 生成4位验证码
func (s *CaptchaService) GenerateCode() string {
	return fmt.Sprintf("%04d", rand.Intn(10000))
}

// GenerateID 生成验证码ID
func (s *CaptchaService) GenerateID() string {
	return fmt.Sprintf("%d%d", time.Now().UnixNano(), rand.Intn(10000))
}

// DrawImage 绘制验证码图片
func (s *CaptchaService) DrawImage(code string) (string, error) {
	const width = 120
	const height = 40

	dc := gg.NewContext(width, height)

	// 背景
	dc.SetRGB(1, 1, 1)
	dc.Clear()

	// 绘制干扰线
	for i := 0; i < 5; i++ {
		dc.SetRGB(rand.Float64(), rand.Float64(), rand.Float64())
		x1 := rand.Float64() * width
		y1 := rand.Float64() * height
		x2 := rand.Float64() * width
		y2 := rand.Float64() * height
		dc.DrawLine(x1, y1, x2, y2)
		dc.Stroke()
	}

	// 绘制干扰点
	for i := 0; i < 50; i++ {
		dc.SetRGB(rand.Float64(), rand.Float64(), rand.Float64())
		x := rand.Float64() * width
		y := rand.Float64() * height
		dc.DrawPoint(x, y, 1)
		dc.Fill()
	}

	// 绘制验证码
	dc.SetRGB(0, 0, 0)
	for i, ch := range code {
		x := 20 + float64(i)*25
		y := 28 + rand.Float64()*8 - 4
		dc.Push()
		dc.Translate(x, y)
		dc.Rotate((rand.Float64() - 0.5) * 0.5)
		dc.DrawStringAnchored(string(ch), 0, 0, 0.5, 0.5)
		dc.Pop()
	}

	// 边框
	dc.SetRGB(0.8, 0.8, 0.8)
	dc.SetLineWidth(1)
	dc.DrawRectangle(0, 0, width, height)
	dc.Stroke()

	var buf bytes.Buffer
	if err := dc.EncodePNG(&buf); err != nil {
		return "", err
	}

	base64Image := base64.StdEncoding.EncodeToString(buf.Bytes())
	return "data:image/png;base64," + base64Image, nil
}

// Save 保存验证码
func (s *CaptchaService) Save(id, code string) error {
	captcha := &models.Captcha{
		ID:        id,
		Code:      code,
		CreatedAt: time.Now(),
	}
	return config.DB.Create(captcha).Error
}

// Verify 验证验证码
func (s *CaptchaService) Verify(id, code string) bool {
	var captcha models.Captcha
	result := config.DB.Where("id = ?", id).First(&captcha)
	if result.Error != nil {
		return false
	}

	if time.Since(captcha.CreatedAt) > config.CaptchaExpire {
		return false
	}

	return captcha.Code == code
}

// Clear 清除验证码
func (s *CaptchaService) Clear(id string) {
	config.DB.Where("id = ?", id).Delete(&models.Captcha{})
}

// CleanExpired 清理过期验证码
func (s *CaptchaService) CleanExpired() {
	expirationTime := time.Now().Add(-config.CaptchaExpire)
	config.DB.Where("created_at < ?", expirationTime).Delete(&models.Captcha{})
}
