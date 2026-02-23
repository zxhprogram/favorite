package services

import (
	"favicon-service/models"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/PuerkitoBio/goquery"
)

// GitHubService GitHub服务
type GitHubService struct {
	client *http.Client
}

// NewGitHubService 创建GitHub服务
func NewGitHubService() *GitHubService {
	return &GitHubService{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// GetTrendingRepositories 获取GitHub Trending仓库列表
func (s *GitHubService) GetTrendingRepositories(language, since string) ([]models.GitHubTrendingRepository, error) {
	// 构建GitHub Trending URL
	url := "https://github.com/trending"
	if language != "" {
		url = fmt.Sprintf("%s/%s", url, language)
	}
	if since != "" {
		url = fmt.Sprintf("%s?since=%s", url, since)
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	// 设置请求头模拟浏览器
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
	req.Header.Set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
	req.Header.Set("Accept-Language", "en-US,en;q=0.5")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GitHub返回错误状态码: %d", resp.StatusCode)
	}

	// 解析HTML
	doc, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		return nil, err
	}

	var repositories []models.GitHubTrendingRepository

	// 查找所有仓库项
	doc.Find("article.Box-row").Each(func(i int, sel *goquery.Selection) {
		repo := parseRepository(sel)
		if repo != nil {
			repositories = append(repositories, *repo)
		}
	})

	return repositories, nil
}

// parseRepository 解析单个仓库信息
func parseRepository(s *goquery.Selection) *models.GitHubTrendingRepository {
	// 获取仓库链接和名称
	linkElem := s.Find("h2 a")
	href, exists := linkElem.Attr("href")
	if !exists {
		return nil
	}

	// 解析作者和仓库名
	parts := strings.Split(strings.Trim(href, "/"), "/")
	if len(parts) < 2 {
		return nil
	}
	author := parts[0]
	name := parts[1]

	// 构建完整URL
	repoURL := "https://github.com" + href

	// 获取描述
	description := strings.TrimSpace(s.Find("p.col-9").Text())

	// 获取编程语言
	language := ""
	languageElem := s.Find("[itemprop='programmingLanguage']")
	if languageElem.Length() > 0 {
		language = strings.TrimSpace(languageElem.Text())
	}

	// 获取语言颜色
	languageColor := ""
	colorElem := s.Find(".repo-language-color")
	if colorElem.Length() > 0 {
		style, _ := colorElem.Attr("style")
		if strings.Contains(style, "background-color:") {
			languageColor = strings.TrimSpace(strings.TrimPrefix(style, "background-color:"))
		}
	}

	// 获取stars和forks
	stars := 0
	forks := 0

	// 查找所有链接文本
	s.Find("a.Link--muted").Each(func(i int, link *goquery.Selection) {
		text := strings.TrimSpace(link.Text())
		linkHref, _ := link.Attr("href")
		if strings.Contains(linkHref, "/stargazers") {
			stars = parseCount(text)
		} else if strings.Contains(linkHref, "/forks") {
			forks = parseCount(text)
		}
	})

	// 获取今日新增stars
	currentPeriodStars := 0
	starsText := strings.TrimSpace(s.Find(".float-sm-right").Text())
	if starsText != "" {
		currentPeriodStars = parseStarsToday(starsText)
	}

	// 获取贡献者
	var builtBy []models.GitHubContributor
	s.Find(".avatar").Each(func(i int, avatar *goquery.Selection) {
		username, _ := avatar.Attr("alt")
		avatarURL, _ := avatar.Attr("src")
		if username != "" {
			// 去掉 "@" 前缀
			username = strings.TrimPrefix(username, "@")
			builtBy = append(builtBy, models.GitHubContributor{
				Username: username,
				Href:     "https://github.com/" + username,
				Avatar:   avatarURL,
			})
		}
	})

	// 构建头像URL
	avatar := fmt.Sprintf("https://avatars.githubusercontent.com/%s?s=48&v=4", author)

	return &models.GitHubTrendingRepository{
		Author:             author,
		Name:               name,
		Avatar:             avatar,
		URL:                repoURL,
		Description:        description,
		Language:           language,
		LanguageColor:      languageColor,
		Stars:              stars,
		Forks:              forks,
		CurrentPeriodStars: currentPeriodStars,
		BuiltBy:            builtBy,
	}
}

// parseCount 解析数字字符串（如 "1.2k" -> 1200）
func parseCount(text string) int {
	text = strings.TrimSpace(text)
	text = strings.ReplaceAll(text, ",", "")

	if strings.Contains(text, "k") {
		var num float64
		fmt.Sscanf(text, "%fk", &num)
		return int(num * 1000)
	}
	if strings.Contains(text, "K") {
		var num float64
		fmt.Sscanf(text, "%fK", &num)
		return int(num * 1000)
	}

	var num int
	fmt.Sscanf(text, "%d", &num)
	return num
}

// parseStarsToday 解析今日新增stars（如 "123 stars today"）
func parseStarsToday(text string) int {
	// 提取数字部分
	parts := strings.Fields(text)
	if len(parts) > 0 {
		return parseCount(parts[0])
	}
	return 0
}
