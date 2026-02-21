package config

import "time"

// 应用配置常量
const (
	ChromeUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0"
	JWTSecret       = "your-secret-key-change-this-in-production"
	JWTExpireHours  = 24
	CaptchaExpire   = 5 * time.Minute
	UploadDir       = "./uploads"
	DatabasePath    = "app.db"
	ServerPort      = ":8081"
)
