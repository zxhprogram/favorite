package handlers

import (
	"encoding/json"
	"favicon-service/models"
	"favicon-service/services"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
)

// GitHubHandler GitHub处理器
type GitHubHandler struct {
	service *services.GitHubService
}

// NewGitHubHandler 创建GitHub处理器
func NewGitHubHandler() *GitHubHandler {
	return &GitHubHandler{
		service: services.NewGitHubService(),
	}
}

// GetTrendingRepositories 获取GitHub Trending仓库列表
func (h *GitHubHandler) GetTrendingRepositories(c *gin.Context) {
	var req models.GitHubTrendingRequest
	b, _ := io.ReadAll(c.Request.Body)
	err := json.Unmarshal(b, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.GitHubTrendingResponse{
			Success: false,
			Error:   "请求参数错误: " + err.Error(),
		})
		return
	}

	// 验证since参数
	if req.Since != "" && req.Since != "daily" && req.Since != "weekly" && req.Since != "monthly" {
		c.JSON(http.StatusBadRequest, models.GitHubTrendingResponse{
			Success: false,
			Error:   "since参数必须是 daily、weekly 或 monthly",
		})
		return
	}

	// 从GitHub页面解析数据
	repositories, err := h.service.GetTrendingRepositories(req.Language, req.Since)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.GitHubTrendingResponse{
			Success: false,
			Error:   "获取GitHub Trending数据失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.GitHubTrendingResponse{
		Success:      true,
		Repositories: repositories,
	})
}

// GetLanguages 获取GitHub Trending支持的所有编程语言列表
func (h *GitHubHandler) GetLanguages(c *gin.Context) {
	languages, err := h.service.GetLanguages()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.GitHubLanguagesResponse{
			Success: false,
			Error:   "获取编程语言列表失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.GitHubLanguagesResponse{
		Success:   true,
		Languages: languages,
	})
}
