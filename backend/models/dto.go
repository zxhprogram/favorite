package models

// URLInfoRequest URL信息请求
type URLInfoRequest struct {
	URL string `json:"url" binding:"required"`
}

// URLInfoResponse URL信息响应
type URLInfoResponse struct {
	Success    bool   `json:"success"`
	URL        string `json:"url,omitempty"`
	Title      string `json:"title,omitempty"`
	FaviconURL string `json:"favicon_url,omitempty"`
	Data       string `json:"data,omitempty"`
	MimeType   string `json:"mime_type,omitempty"`
	Error      string `json:"error,omitempty"`
}

// PageInfo 页面信息
type PageInfo struct {
	Title      string
	FaviconURL string
}

// RegisterRequest 注册请求
type RegisterRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required,min=6"`
	Nickname    string `json:"nickname" binding:"required"`
	CaptchaID   string `json:"captcha_id" binding:"required"`
	CaptchaCode string `json:"captcha_code" binding:"required,len=4"`
}

// LoginRequest 登录请求
type LoginRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required"`
	CaptchaID   string `json:"captcha_id" binding:"required"`
	CaptchaCode string `json:"captcha_code" binding:"required,len=4"`
}

// AuthResponse 认证响应
type AuthResponse struct {
	Success  bool   `json:"success"`
	Token    string `json:"token,omitempty"`
	Nickname string `json:"nickname,omitempty"`
	Avatar   string `json:"avatar,omitempty"`
	Message  string `json:"message,omitempty"`
	Error    string `json:"error,omitempty"`
}

// CaptchaResponse 验证码响应
type CaptchaResponse struct {
	Success   bool   `json:"success"`
	CaptchaID string `json:"captcha_id,omitempty"`
	Image     string `json:"image,omitempty"`
	Error     string `json:"error,omitempty"`
}

// UploadResponse 上传响应
type UploadResponse struct {
	Success bool   `json:"success"`
	URL     string `json:"url,omitempty"`
	Message string `json:"message,omitempty"`
	Error   string `json:"error,omitempty"`
}

// UpdateAvatarRequest 更新头像请求
type UpdateAvatarRequest struct {
	AvatarURL string `json:"avatar_url" binding:"required,url"`
}

// UpdateAvatarResponse 更新头像响应
type UpdateAvatarResponse struct {
	Success bool   `json:"success"`
	Avatar  string `json:"avatar,omitempty"`
	Message string `json:"message,omitempty"`
	Error   string `json:"error,omitempty"`
}

// CreateBookmarkRequest 创建书签请求
type CreateBookmarkRequest struct {
	Name         string `json:"name" binding:"required"`
	IconURL      string `json:"icon_url" binding:"omitempty,url"`
	IconMimeType string `json:"icon_mime_type"`
	URL          string `json:"url" binding:"required,url"`
	Description  string `json:"description"`
}

// UpdateBookmarkRequest 更新书签请求
type UpdateBookmarkRequest struct {
	Name         string `json:"name" binding:"required"`
	IconURL      string `json:"icon_url" binding:"omitempty,url"`
	IconMimeType string `json:"icon_mime_type"`
	URL          string `json:"url" binding:"required,url"`
	Description  string `json:"description"`
}

// BookmarkResponse 书签响应
type BookmarkResponse struct {
	Success   bool       `json:"success"`
	Bookmark  *Bookmark  `json:"bookmark,omitempty"`
	Bookmarks []Bookmark `json:"bookmarks,omitempty"`
	Message   string     `json:"message,omitempty"`
	Error     string     `json:"error,omitempty"`
}
