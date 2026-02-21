package models

import "time"

// Captcha 验证码模型
type Captcha struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	Code      string    `gorm:"not null" json:"code"`
	CreatedAt time.Time `json:"created_at"`
}
