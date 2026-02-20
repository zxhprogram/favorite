package main

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/fogleman/gg"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const (
	chromeUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36 Edg/144.0.0.0"
	jwtSecret       = "your-secret-key-change-this-in-production"
	jwtExpireHours  = 24
	captchaExpire   = 5 * time.Minute
)

// URL Info types
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

// User types
type User struct {
	Email     string    `json:"email"`
	Password  string    `json:"password"`
	Nickname  string    `json:"nickname"`
	CreatedAt time.Time `json:"created_at"`
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
	Success bool   `json:"success"`
	Token   string `json:"token,omitempty"`
	Message string `json:"message,omitempty"`
	Error   string `json:"error,omitempty"`
}

type CaptchaResponse struct {
	Success   bool   `json:"success"`
	CaptchaID string `json:"captcha_id,omitempty"`
	Image     string `json:"image,omitempty"`
	Error     string `json:"error,omitempty"`
}

// Captcha info
type CaptchaInfo struct {
	Code      string
	CreatedAt time.Time
}

// In-memory storage
type Store struct {
	users    map[string]*User
	captchas map[string]*CaptchaInfo
	mu       sync.RWMutex
}

var store = &Store{
	users:    make(map[string]*User),
	captchas: make(map[string]*CaptchaInfo),
}

// JWT Claims
type JWTClaims struct {
	Email    string `json:"email"`
	Nickname string `json:"nickname"`
	jwt.RegisteredClaims
}

func main() {
	r := gin.Default()

	r.POST("/urlInfo", handleURLInfo)

	// Auth routes
	r.GET("/auth/captcha", handleGetCaptcha)
	r.POST("/auth/register", handleRegister)
	r.POST("/auth/login", handleLogin)

	r.Run(":8081")
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
	store.mu.Lock()
	defer store.mu.Unlock()

	now := time.Now()
	for id, info := range store.captchas {
		if now.Sub(info.CreatedAt) > captchaExpire {
			delete(store.captchas, id)
		}
	}
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

	store.mu.Lock()
	store.captchas[captchaID] = &CaptchaInfo{
		Code:      code,
		CreatedAt: time.Now(),
	}
	store.mu.Unlock()

	base64Image := base64.StdEncoding.EncodeToString(imageData)

	c.JSON(http.StatusOK, CaptchaResponse{
		Success:   true,
		CaptchaID: captchaID,
		Image:     "data:image/png;base64," + base64Image,
	})
}

// Verify captcha
func verifyCaptcha(captchaID, code string) bool {
	store.mu.RLock()
	info, exists := store.captchas[captchaID]
	store.mu.RUnlock()

	if !exists {
		return false
	}

	if time.Since(info.CreatedAt) > captchaExpire {
		return false
	}

	return strings.EqualFold(info.Code, code)
}

// Clear captcha after use
func clearCaptcha(captchaID string) {
	store.mu.Lock()
	delete(store.captchas, captchaID)
	store.mu.Unlock()
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
	store.mu.RLock()
	_, exists := store.users[req.Email]
	store.mu.RUnlock()

	if exists {
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

	store.mu.Lock()
	store.users[req.Email] = user
	store.mu.Unlock()

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
	store.mu.RLock()
	user, exists := store.users[req.Email]
	store.mu.RUnlock()

	if !exists || user.Password != req.Password {
		c.JSON(http.StatusUnauthorized, AuthResponse{
			Success: false,
			Error:   "邮箱或密码错误",
		})
		return
	}

	// Generate JWT token
	token, err := generateToken(user)
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
		Success: true,
		Token:   token,
		Message: "登录成功",
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
