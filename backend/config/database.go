package config

import (
	"favicon-service/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DB 全局数据库连接
var DB *gorm.DB

// InitDatabase 初始化数据库
func InitDatabase() error {
	var err error
	DB, err = gorm.Open(sqlite.Open(DatabasePath), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		return err
	}

	// 自动迁移表结构
	return DB.AutoMigrate(&models.User{}, &models.Captcha{}, &models.Bookmark{})
}
