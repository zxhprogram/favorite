package services

import (
	"favicon-service/config"
	"fmt"
	"io"
	"math/rand"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// UploadService 上传服务
type UploadService struct{}

// NewUploadService 创建上传服务
func NewUploadService() *UploadService {
	return &UploadService{}
}

// UploadAvatar 上传头像
func (s *UploadService) UploadAvatar(file multipart.File, header *multipart.FileHeader) (string, error) {
	// 检查文件大小（最大5MB）
	if header.Size > 5*1024*1024 {
		return "", fmt.Errorf("文件大小不能超过5MB")
	}

	// 检查文件类型
	buffer := make([]byte, 512)
	_, err := file.Read(buffer)
	if err != nil {
		return "", fmt.Errorf("读取文件失败")
	}
	file.Seek(0, 0)

	contentType := http.DetectContentType(buffer)
	if !strings.HasPrefix(contentType, "image/") {
		return "", fmt.Errorf("只能上传图片文件")
	}

	// 生成唯一文件名
	ext := filepath.Ext(header.Filename)
	if ext == "" {
		ext = ".jpg"
	}
	filename := fmt.Sprintf("%d%d%s", time.Now().UnixNano(), rand.Intn(10000), ext)
	filePath := filepath.Join(config.UploadDir, "avatars", filename)

	// 保存文件
	out, err := os.Create(filePath)
	if err != nil {
		return "", fmt.Errorf("保存文件失败")
	}
	defer out.Close()

	_, err = io.Copy(out, file)
	if err != nil {
		return "", fmt.Errorf("保存文件失败")
	}

	// 返回URL
	return fmt.Sprintf("/uploads/avatars/%s", filename), nil
}

// InitUploadDir 初始化上传目录
func (s *UploadService) InitUploadDir() error {
	return os.MkdirAll(filepath.Join(config.UploadDir, "avatars"), os.ModePerm)
}
