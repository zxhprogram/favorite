package services

import (
	"favicon-service/config"
	"favicon-service/models"
	"time"
)

// BookmarkService 书签服务
type BookmarkService struct{}

// NewBookmarkService 创建书签服务
func NewBookmarkService() *BookmarkService {
	return &BookmarkService{}
}

// Create 创建书签
func (s *BookmarkService) Create(userEmail string, req *models.CreateBookmarkRequest) (*models.Bookmark, error) {
	bookmark := &models.Bookmark{
		UserEmail:    userEmail,
		Name:         req.Name,
		IconURL:      req.IconURL,
		IconMimeType: req.IconMimeType,
		URL:          req.URL,
		Description:  req.Description,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
	if err := config.DB.Create(bookmark).Error; err != nil {
		return nil, err
	}
	return bookmark, nil
}

// GetByID 根据ID获取书签
func (s *BookmarkService) GetByID(id uint, userEmail string) (*models.Bookmark, error) {
	var bookmark models.Bookmark
	result := config.DB.Where("id = ? AND user_email = ?", id, userEmail).First(&bookmark)
	if result.Error != nil {
		return nil, result.Error
	}
	return &bookmark, nil
}

// GetAllByUser 获取用户的所有书签
func (s *BookmarkService) GetAllByUser(userEmail string) ([]models.Bookmark, error) {
	var bookmarks []models.Bookmark
	result := config.DB.Where("user_email = ?", userEmail).Order("created_at DESC").Find(&bookmarks)
	if result.Error != nil {
		return nil, result.Error
	}
	return bookmarks, nil
}

// Update 更新书签
func (s *BookmarkService) Update(id uint, userEmail string, req *models.UpdateBookmarkRequest) (*models.Bookmark, error) {
	var bookmark models.Bookmark
	result := config.DB.Where("id = ? AND user_email = ?", id, userEmail).First(&bookmark)
	if result.Error != nil {
		return nil, result.Error
	}

	bookmark.Name = req.Name
	bookmark.IconURL = req.IconURL
	bookmark.IconMimeType = req.IconMimeType
	bookmark.URL = req.URL
	bookmark.Description = req.Description
	bookmark.UpdatedAt = time.Now()

	if err := config.DB.Save(&bookmark).Error; err != nil {
		return nil, err
	}
	return &bookmark, nil
}

// Delete 删除书签
func (s *BookmarkService) Delete(id uint, userEmail string) error {
	result := config.DB.Where("id = ? AND user_email = ?", id, userEmail).Delete(&models.Bookmark{})
	if result.Error != nil {
		return result.Error
	}
	return nil
}

// Exists 检查书签是否存在
func (s *BookmarkService) Exists(id uint, userEmail string) bool {
	var bookmark models.Bookmark
	result := config.DB.Where("id = ? AND user_email = ?", id, userEmail).First(&bookmark)
	return result.Error == nil
}
