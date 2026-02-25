package services

import (
	"favicon-service/config"
	"favicon-service/models"
	"time"
)

type FolderService struct{}

func NewFolderService() *FolderService {
	return &FolderService{}
}

func (s *FolderService) Create(userEmail string, req *models.CreateFolderRequest) (*models.Folder, error) {
	folder := &models.Folder{
		UserEmail: userEmail,
		Name:      req.Name,
		SortOrder: 0,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if err := config.DB.Create(folder).Error; err != nil {
		return nil, err
	}
	return folder, nil
}

func (s *FolderService) GetAllByUser(userEmail string) ([]models.Folder, error) {
	var folders []models.Folder
	result := config.DB.Where("user_email = ?", userEmail).Order("sort_order ASC, created_at DESC").Find(&folders)
	if result.Error != nil {
		return nil, result.Error
	}
	return folders, nil
}

func (s *FolderService) GetByID(id uint, userEmail string) (*models.Folder, error) {
	var folder models.Folder
	result := config.DB.Where("id = ? AND user_email = ?", id, userEmail).First(&folder)
	if result.Error != nil {
		return nil, result.Error
	}
	return &folder, nil
}

func (s *FolderService) Update(id uint, userEmail string, req *models.UpdateFolderRequest) (*models.Folder, error) {
	var folder models.Folder
	result := config.DB.Where("id = ? AND user_email = ?", id, userEmail).First(&folder)
	if result.Error != nil {
		return nil, result.Error
	}
	folder.Name = req.Name
	folder.UpdatedAt = time.Now()
	if err := config.DB.Save(&folder).Error; err != nil {
		return nil, err
	}
	return &folder, nil
}

func (s *FolderService) Delete(id uint, userEmail string) error {
	result := config.DB.Where("id = ? AND user_email = ?", id, userEmail).Delete(&models.Folder{})
	if result.Error != nil {
		return result.Error
	}
	config.DB.Model(&models.Bookmark{}).Where("folder_id = ? AND user_email = ?", id, userEmail).Update("folder_id", nil)
	return nil
}

func (s *FolderService) MoveBookmarkToFolder(userEmail string, req *models.MoveBookmarkToFolderRequest) error {
	return config.DB.Model(&models.Bookmark{}).
		Where("id = ? AND user_email = ?", req.BookmarkID, userEmail).
		Update("folder_id", req.FolderID).Error
}

func (s *FolderService) GetBookmarksInFolder(folderID uint, userEmail string) ([]models.Bookmark, error) {
	var bookmarks []models.Bookmark
	result := config.DB.Where("folder_id = ? AND user_email = ?", folderID, userEmail).
		Order("sort_order ASC, created_at DESC").
		Find(&bookmarks)
	if result.Error != nil {
		return nil, result.Error
	}
	return bookmarks, nil
}
