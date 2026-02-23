package models

import "time"

// Bookmark 书签模型
type Bookmark struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	UserEmail    string    `gorm:"index;not null" json:"user_email"`
	Name         string    `gorm:"not null" json:"name"`
	IconURL      string    `gorm:"default:''" json:"icon_url"`
	IconMimeType string    `gorm:"default:''" json:"icon_mime_type"`
	URL          string    `gorm:"not null" json:"url"`
	Description  string    `gorm:"default:''" json:"description"`
	SortOrder    int       `gorm:"default:0" json:"sort_order"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}
