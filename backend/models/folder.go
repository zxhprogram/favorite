package models

import "time"

type Folder struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserEmail string    `gorm:"index;not null" json:"user_email"`
	Name      string    `gorm:"not null" json:"name"`
	SortOrder int       `gorm:"default:0" json:"sort_order"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type CreateFolderRequest struct {
	Name string `json:"name" binding:"required"`
}

type UpdateFolderRequest struct {
	Name string `json:"name" binding:"required"`
}

type FolderResponse struct {
	Success bool     `json:"success"`
	Folder  *Folder  `json:"folder,omitempty"`
	Folders []Folder `json:"folders,omitempty"`
	Message string   `json:"message,omitempty"`
	Error   string   `json:"error,omitempty"`
}

type MoveBookmarkToFolderRequest struct {
	BookmarkID uint  `json:"bookmark_id" binding:"required"`
	FolderID   *uint `json:"folder_id"`
}
