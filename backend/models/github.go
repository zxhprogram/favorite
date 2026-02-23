package models

// GitHubTrendingRepository GitHub Trending仓库信息
type GitHubTrendingRepository struct {
	Author             string              `json:"author"`
	Name               string              `json:"name"`
	Avatar             string              `json:"avatar"`
	URL                string              `json:"url"`
	Description        string              `json:"description"`
	Language           string              `json:"language"`
	LanguageColor      string              `json:"languageColor"`
	Stars              int                 `json:"stars"`
	Forks              int                 `json:"forks"`
	CurrentPeriodStars int                 `json:"currentPeriodStars"`
	BuiltBy            []GitHubContributor `json:"builtBy"`
}

// GitHubContributor 贡献者信息
type GitHubContributor struct {
	Username string `json:"username"`
	Href     string `json:"href"`
	Avatar   string `json:"avatar"`
}

// GitHubTrendingRequest GitHub Trending请求
type GitHubTrendingRequest struct {
	Language string `json:"language"`
	Since    string `json:"since"` // daily, weekly, monthly
}

// GitHubTrendingResponse GitHub Trending响应
type GitHubTrendingResponse struct {
	Success      bool                       `json:"success"`
	Repositories []GitHubTrendingRepository `json:"repositories,omitempty"`
	Message      string                     `json:"message,omitempty"`
	Error        string                     `json:"error,omitempty"`
}

// GitHubLanguage 编程语言信息
type GitHubLanguage struct {
	Name  string `json:"name"`
	URL   string `json:"url"`
	Color string `json:"color,omitempty"`
}

// GitHubLanguagesResponse 编程语言列表响应
type GitHubLanguagesResponse struct {
	Success   bool             `json:"success"`
	Languages []GitHubLanguage `json:"languages,omitempty"`
	Message   string           `json:"message,omitempty"`
	Error     string           `json:"error,omitempty"`
}
