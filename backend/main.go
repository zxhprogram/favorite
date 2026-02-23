package main

import (
	"favicon-service/config"
	"favicon-service/handlers"
	"favicon-service/middleware"
	"favicon-service/services"
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	// 初始化数据库
	if err := config.InitDatabase(); err != nil {
		log.Fatal("数据库初始化失败:", err)
	}

	// 初始化上传目录
	uploadService := services.NewUploadService()
	if err := uploadService.InitUploadDir(); err != nil {
		log.Fatal("上传目录初始化失败:", err)
	}

	// 创建Gin引擎
	r := gin.Default()

	// 全局中间件
	r.Use(middleware.CORS())

	// 静态文件服务
	r.Static("/uploads", config.UploadDir)

	// 创建处理器
	captchaHandler := handlers.NewCaptchaHandler()
	authHandler := handlers.NewAuthHandler()
	urlInfoHandler := handlers.NewURLInfoHandler()
	userHandler := handlers.NewUserHandler()
	bookmarkHandler := handlers.NewBookmarkHandler()
	publicHandler := handlers.NewPublicHandler()
	githubHandler := handlers.NewGitHubHandler()

	// 公开路由
	r.POST("/urlInfo", urlInfoHandler.GetURLInfo)
	r.GET("/auth/captcha", captchaHandler.GetCaptcha)
	r.POST("/auth/register", authHandler.Register)
	r.POST("/auth/login", authHandler.Login)
	r.GET("/public/bookmarks", publicHandler.GetPublicBookmarks)
	r.POST("/github/trending", githubHandler.GetTrendingRepositories)

	// 需要认证的路由
	authorized := r.Group("/")
	authorized.Use(middleware.Auth())
	{
		authorized.POST("/user/avatar", userHandler.UpdateAvatar)

		// 书签相关路由
		authorized.POST("/bookmarks", bookmarkHandler.Create)
		authorized.GET("/bookmarks", bookmarkHandler.GetAll)
		authorized.GET("/bookmarks/:id", bookmarkHandler.GetByID)
		authorized.PUT("/bookmarks/:id", bookmarkHandler.Update)
		authorized.DELETE("/bookmarks/:id", bookmarkHandler.Delete)
		authorized.POST("/bookmarks/sort", bookmarkHandler.Sort)
	}

	// 启动服务器
	if err := r.Run(config.ServerPort); err != nil {
		log.Fatal("服务器启动失败:", err)
	}
}
