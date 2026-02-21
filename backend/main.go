package main

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/fogleman/gg"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

const (
	chromeUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0"
	jwtSecret       = "your-secret-key-change-this-in-production"
	jwtExpireHours  = 24
	captchaExpire   = 5 * time.Minute
	uploadDir       = "./uploads"
)

var db *gorm.DB

// Database models
type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Email     string    `gorm:"uniqueIndex;not null" json:"email"`
	Password  string    `gorm:"not null" json:"password"`
	Nickname  string    `gorm:"not null" json:"nickname"`
	Avatar    string    `gorm:"default:''" json:"avatar"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Captcha struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	Code      string    `gorm:"not null" json:"code"`
	CreatedAt time.Time `json:"created_at"`
}

// Request/Response types
type URLInfoRequest struct {
	URL string `json:"url" binding:"required"`
}

type URLInfoResponse struct {
	Success    bool   `json:"success"`
	URL        string `json:"url,omitempty"`
	Title      string `json:"title,omitempty"`
	FaviconURL string `json:"favicon_url,omitempty"`
	Data       string `json:"data,omitempty"`
	MimeType   string `json:"mime_type,omitempty"`
	Error      string `json:"error,omitempty"`
}

type PageInfo struct {
	Title      string
	FaviconURL string
}

type RegisterRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required,min=6"`
	Nickname    string `json:"nickname" binding:"required"`
	CaptchaID   string `json:"captcha_id" binding:"required"`
	CaptchaCode string `json:"captcha_code" binding:"required,len=4"`
}

type LoginRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required"`
	CaptchaID   string `json:"captcha_id" binding:"required"`
	CaptchaCode string `json:"captcha_code" binding:"required,len=4"`
}

type AuthResponse struct {
	Success  bool   `json:"success"`
	Token    string `json:"token,omitempty"`
	Nickname string `json:"nickname,omitempty"`
	Message  string `json:"message,omitempty"`
	Error    string `json:"error,omitempty"`
}

type CaptchaResponse struct {
	Success   bool   `json:"success"`
	CaptchaID string `json:"captcha_id,omitempty"`
	Image     string `json:"image,omitempty"`
	Error     string `json:"error,omitempty"`
}

type UploadResponse struct {
	Success bool   `json:"success"`
	URL     string `json:"url,omitempty"`
	Message string `json:"message,omitempty"`
	Error   string `json:"error,omitempty"`
}

type UpdateAvatarRequest struct {
	AvatarURL string `json:"avatar_url" binding:"required,url"`
}

type UpdateAvatarResponse struct {
	Success bool   `json:"success"`
	Avatar  string `json:"avatar,omitempty"`
	Message string `json:"message,omitempty"`
	Error   string `json:"error,omitempty"`
}

// JWT Claims
type JWTClaims struct {
	Email    string `json:"email"`
	Nickname string `json:"nickname"`
	jwt.RegisteredClaims
}

func main() {
	var err error
	// Initialize SQLite database
	db, err = gorm.Open(sqlite.Open("app.db"), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		panic("failed to connect database")
	}

	// Auto migrate tables
	db.AutoMigrate(&User{}, &Captcha{})

	// Create upload directory
	os.MkdirAll(uploadDir+"/avatars", os.ModePerm)

	r := gin.Default()

	// CORS middleware
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept")
		c.Writer.Header().Set("Access-Control-Max-Age", "86400")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Static file server for uploads
	r.Static("/uploads", uploadDir)

	r.POST("/urlInfo", handleURLInfo)

	// Auth routes
	r.GET("/auth/captcha", handleGetCaptcha)
	r.POST("/auth/register", handleRegister)
	r.POST("/auth/login", handleLogin)

	// Upload route (no auth required for upload)
	r.POST("/upload/avatar", handleUploadAvatar)

	// Protected routes
	authorized := r.Group("/")
	authorized.Use(authMiddleware())
	{
		authorized.POST("/user/avatar", handleUpdateAvatar)
	}

	r.Run(":8081")
}

// Auth middleware
func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"success": false, "error": "缺少Authorization头"})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>"
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"success": false, "error": "Authorization格式错误"})
			c.Abort()
			return
		}

		tokenString := parts[1]
		claims := &JWTClaims{}

		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(jwtSecret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"success": false, "error": "Token无效或已过期"})
			c.Abort()
			return
		}

		// Set user email in context
		c.Set("userEmail", claims.Email)
		c.Next()
	}
}

// Generate 4-digit captcha code
func generateCaptchaCode() string {
	return fmt.Sprintf("%04d", rand.Intn(10000))
}

// Generate captcha ID
func generateCaptchaID() string {
	return fmt.Sprintf("%d%d", time.Now().UnixNano(), rand.Intn(10000))
}

// Draw captcha image
func drawCaptchaImage(code string) ([]byte, error) {
	const width = 120
	const height = 40

	dc := gg.NewContext(width, height)

	// Background
	dc.SetRGB(1, 1, 1)
	dc.Clear()

	// Draw noise lines
	for i := 0; i < 5; i++ {
		dc.SetRGB(rand.Float64(), rand.Float64(), rand.Float64())
		x1 := rand.Float64() * width
		y1 := rand.Float64() * height
		x2 := rand.Float64() * width
		y2 := rand.Float64() * height
		dc.DrawLine(x1, y1, x2, y2)
		dc.Stroke()
	}

	// Draw noise dots
	for i := 0; i < 50; i++ {
		dc.SetRGB(rand.Float64(), rand.Float64(), rand.Float64())
		x := rand.Float64() * width
		y := rand.Float64() * height
		dc.DrawPoint(x, y, 1)
		dc.Fill()
	}

	// Draw code
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

	// Border
	dc.SetRGB(0.8, 0.8, 0.8)
	dc.SetLineWidth(1)
	dc.DrawRectangle(0, 0, width, height)
	dc.Stroke()

	var buf bytes.Buffer
	err := dc.EncodePNG(&buf)
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

// Clean expired captchas
func cleanExpiredCaptchas() {
	expirationTime := time.Now().Add(-captchaExpire)
	db.Where("created_at < ?", expirationTime).Delete(&Captcha{})
}

// Get captcha handler
func handleGetCaptcha(c *gin.Context) {
	cleanExpiredCaptchas()

	code := generateCaptchaCode()
	captchaID := generateCaptchaID()

	imageData, err := drawCaptchaImage(code)
	if err != nil {
		c.JSON(http.StatusInternalServerError, CaptchaResponse{
			Success: false,
			Error:   "生成验证码失败",
		})
		return
	}

	// Save to database
	captcha := &Captcha{
		ID:        captchaID,
		Code:      code,
		CreatedAt: time.Now(),
	}
	db.Create(captcha)

	base64Image := base64.StdEncoding.EncodeToString(imageData)

	c.JSON(http.StatusOK, CaptchaResponse{
		Success:   true,
		CaptchaID: captchaID,
		Image:     "data:image/png;base64," + base64Image,
	})
}

// Verify captcha
func verifyCaptcha(captchaID, code string) bool {
	var captcha Captcha
	result := db.Where("id = ?", captchaID).First(&captcha)
	if result.Error != nil {
		return false
	}

	if time.Since(captcha.CreatedAt) > captchaExpire {
		return false
	}

	return strings.EqualFold(captcha.Code, code)
}

// Clear captcha after use
func clearCaptcha(captchaID string) {
	db.Where("id = ?", captchaID).Delete(&Captcha{})
}

// Register handler
func handleRegister(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, AuthResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// Verify captcha
	if !verifyCaptcha(req.CaptchaID, req.CaptchaCode) {
		c.JSON(http.StatusBadRequest, AuthResponse{
			Success: false,
			Error:   "验证码错误或已过期",
		})
		return
	}

	// Check if user already exists
	var existingUser User
	result := db.Where("email = ?", req.Email).First(&existingUser)
	if result.Error == nil {
		c.JSON(http.StatusConflict, AuthResponse{
			Success: false,
			Error:   "该邮箱已被注册",
		})
		return
	}

	// Create user
	user := &User{
		Email:     req.Email,
		Password:  req.Password,
		Nickname:  req.Nickname,
		CreatedAt: time.Now(),
	}

	result = db.Create(user)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, AuthResponse{
			Success: false,
			Error:   "注册失败",
		})
		return
	}

	// Clear used captcha
	clearCaptcha(req.CaptchaID)

	c.JSON(http.StatusOK, AuthResponse{
		Success: true,
		Message: "注册成功",
	})
}

// Login handler
func handleLogin(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, AuthResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// Verify captcha
	if !verifyCaptcha(req.CaptchaID, req.CaptchaCode) {
		c.JSON(http.StatusBadRequest, AuthResponse{
			Success: false,
			Error:   "验证码错误或已过期",
		})
		return
	}

	// Verify user credentials
	var user User
	result := db.Where("email = ? AND password = ?", req.Email, req.Password).First(&user)
	if result.Error != nil {
		c.JSON(http.StatusUnauthorized, AuthResponse{
			Success: false,
			Error:   "邮箱或密码错误",
		})
		return
	}

	// Generate JWT token
	token, err := generateToken(&user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, AuthResponse{
			Success: false,
			Error:   "生成Token失败",
		})
		return
	}

	// Clear used captcha
	clearCaptcha(req.CaptchaID)

	c.JSON(http.StatusOK, AuthResponse{
		Success:  true,
		Token:    token,
		Nickname: user.Nickname,
		Message:  "登录成功",
	})
}

// Generate JWT token
func generateToken(user *User) (string, error) {
	claims := JWTClaims{
		Email:    user.Email,
		Nickname: user.Nickname,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour * jwtExpireHours)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Subject:   user.Email,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(jwtSecret))
}

// Upload avatar handler
func handleUploadAvatar(c *gin.Context) {
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, UploadResponse{
			Success: false,
			Error:   "获取文件失败: " + err.Error(),
		})
		return
	}
	defer file.Close()

	// Check file size (max 5MB)
	if header.Size > 5*1024*1024 {
		c.JSON(http.StatusBadRequest, UploadResponse{
			Success: false,
			Error:   "文件大小不能超过5MB",
		})
		return
	}

	// Check file type
	buffer := make([]byte, 512)
	_, err = file.Read(buffer)
	if err != nil {
		c.JSON(http.StatusInternalServerError, UploadResponse{
			Success: false,
			Error:   "读取文件失败",
		})
		return
	}
	file.Seek(0, 0)

	contentType := http.DetectContentType(buffer)
	if !strings.HasPrefix(contentType, "image/") {
		c.JSON(http.StatusBadRequest, UploadResponse{
			Success: false,
			Error:   "只能上传图片文件",
		})
		return
	}

	// Generate unique filename
	ext := filepath.Ext(header.Filename)
	if ext == "" {
		ext = ".jpg"
	}
	filename := fmt.Sprintf("%d%d%s", time.Now().UnixNano(), rand.Intn(10000), ext)
	filepath := filepath.Join(uploadDir, "avatars", filename)

	// Save file
	out, err := os.Create(filepath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, UploadResponse{
			Success: false,
			Error:   "保存文件失败",
		})
		return
	}
	defer out.Close()

	_, err = io.Copy(out, file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, UploadResponse{
			Success: false,
			Error:   "保存文件失败",
		})
		return
	}

	// Generate URL
	fileURL := fmt.Sprintf("/uploads/avatars/%s", filename)

	c.JSON(http.StatusOK, UploadResponse{
		Success: true,
		URL:     fileURL,
		Message: "上传成功",
	})
}

// Update avatar handler
func handleUpdateAvatar(c *gin.Context) {
	userEmail, exists := c.Get("userEmail")
	if !exists {
		c.JSON(http.StatusUnauthorized, UpdateAvatarResponse{
			Success: false,
			Error:   "未授权",
		})
		return
	}

	var req UpdateAvatarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, UpdateAvatarResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// Update user avatar
	result := db.Model(&User{}).Where("email = ?", userEmail).Update("avatar", req.AvatarURL)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, UpdateAvatarResponse{
			Success: false,
			Error:   "更新头像失败",
		})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, UpdateAvatarResponse{
			Success: false,
			Error:   "用户不存在",
		})
		return
	}

	c.JSON(http.StatusOK, UpdateAvatarResponse{
		Success: true,
		Avatar:  req.AvatarURL,
		Message: "头像更新成功",
	})
}

// URL Info handler
func handleURLInfo(c *gin.Context) {
	var req URLInfoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, URLInfoResponse{
			Success: false,
			Error:   "缺少url参数",
		})
		return
	}

	targetURL := req.URL
	if !strings.HasPrefix(targetURL, "http://") && !strings.HasPrefix(targetURL, "https://") {
		targetURL = "https://" + targetURL
	}

	parsedURL, err := url.Parse(targetURL)
	if err != nil {
		c.JSON(http.StatusBadRequest, URLInfoResponse{
			Success: false,
			Error:   "无效的URL",
		})
		return
	}

	pageInfo, err := getPageInfo(targetURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, URLInfoResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	faviconURL := pageInfo.FaviconURL
	if faviconURL == "" {
		faviconURL = fmt.Sprintf("%s://%s/favicon.ico", parsedURL.Scheme, parsedURL.Host)
	}

	if !strings.HasPrefix(faviconURL, "http://") && !strings.HasPrefix(faviconURL, "https://") {
		if strings.HasPrefix(faviconURL, "//") {
			faviconURL = parsedURL.Scheme + ":" + faviconURL
		} else if strings.HasPrefix(faviconURL, "/") {
			faviconURL = fmt.Sprintf("%s://%s%s", parsedURL.Scheme, parsedURL.Host, faviconURL)
		} else {
			faviconURL = fmt.Sprintf("%s://%s/%s", parsedURL.Scheme, parsedURL.Host, faviconURL)
		}
	}

	data, mimeType, err := downloadFavicon(faviconURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, URLInfoResponse{
			Success: false,
			Error:   "获取favicon失败: " + err.Error(),
		})
		return
	}

	base64Data := base64.StdEncoding.EncodeToString(data)

	c.JSON(http.StatusOK, URLInfoResponse{
		Success:    true,
		URL:        targetURL,
		Title:      pageInfo.Title,
		FaviconURL: faviconURL,
		Data:       base64Data,
		MimeType:   mimeType,
	})
}

func getPageInfo(targetURL string) (*PageInfo, error) {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return nil
		},
	}

	req, err := http.NewRequest("GET", targetURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", chromeUserAgent)

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	html := string(body)

	pageInfo := &PageInfo{
		Title:      extractTitleFromHTML(html),
		FaviconURL: extractFaviconFromHTML(html),
	}

	return pageInfo, nil
}

func extractTitleFromHTML(html string) string {
	lowerHTML := strings.ToLower(html)

	titleStart := strings.Index(lowerHTML, "<title>")
	if titleStart == -1 {
		titleStart = strings.Index(lowerHTML, "<title ")
	}

	if titleStart != -1 {
		titleStart = strings.Index(html[titleStart:], ">") + titleStart + 1
		titleEnd := strings.Index(lowerHTML[titleStart:], "</title>")

		if titleEnd != -1 {
			title := html[titleStart : titleStart+titleEnd]
			title = strings.TrimSpace(title)
			return title
		}
	}

	return ""
}

func extractFaviconFromHTML(html string) string {
	lowerHTML := strings.ToLower(html)

	linkStart := strings.Index(lowerHTML, "<link")
	for linkStart != -1 {
		linkEnd := strings.Index(lowerHTML[linkStart:], ">")
		if linkEnd == -1 {
			break
		}
		linkEnd += linkStart

		linkTag := lowerHTML[linkStart:linkEnd]
		originalTag := html[linkStart:linkEnd]

		if strings.Contains(linkTag, "rel=\"icon\"") ||
			strings.Contains(linkTag, "rel=\"shortcut icon\"") ||
			strings.Contains(linkTag, "rel='icon'") ||
			strings.Contains(linkTag, "rel='shortcut icon'") ||
			strings.Contains(linkTag, "rel=icon ") ||
			strings.Contains(linkTag, "rel=\"apple-touch-icon\"") ||
			strings.Contains(linkTag, "rel='apple-touch-icon'") {

			hrefStart := strings.Index(linkTag, "href=\"")
			if hrefStart == -1 {
				hrefStart = strings.Index(linkTag, "href='")
				if hrefStart != -1 {
					hrefStart += 6
					hrefEnd := strings.Index(originalTag[hrefStart:], "'")
					if hrefEnd != -1 {
						return originalTag[hrefStart : hrefStart+hrefEnd]
					}
				}
			} else {
				hrefStart += 6
				hrefEnd := strings.Index(originalTag[hrefStart:], "\"")
				if hrefEnd != -1 {
					return originalTag[hrefStart : hrefStart+hrefEnd]
				}
			}
		}

		linkStart = strings.Index(lowerHTML[linkEnd:], "<link")
		if linkStart != -1 {
			linkStart += linkEnd
		}
	}

	return ""
}

func downloadFavicon(faviconURL string) ([]byte, string, error) {
	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return nil
		},
	}

	req, err := http.NewRequest("GET", faviconURL, nil)
	if err != nil {
		return nil, "", err
	}
	req.Header.Set("User-Agent", chromeUserAgent)

	resp, err := client.Do(req)
	if err != nil {
		return nil, "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, "", fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, "", err
	}

	mimeType := resp.Header.Get("Content-Type")
	if mimeType == "" {
		mimeType = detectMimeType(data)
	}

	return data, mimeType, nil
}

func detectMimeType(data []byte) string {
	if len(data) < 4 {
		return "application/octet-stream"
	}

	if data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
		return "image/png"
	}
	if data[0] == 0xFF && data[1] == 0xD8 {
		return "image/jpeg"
	}
	if data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 {
		return "image/gif"
	}
	if data[0] == 0x00 && data[1] == 0x00 && data[2] == 0x01 && data[3] == 0x00 {
		return "image/x-icon"
	}
	if data[0] == 0x3C && (data[1] == 0x3F || data[1] == 0x73) {
		return "image/svg+xml"
	}

	return "application/octet-stream"
}
