package main

import (
	"log/slog"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/trainwithshubham/skillpulse/database"
	"github.com/trainwithshubham/skillpulse/handlers"
)

func main() {
	// Structured JSON logger — every log line is machine-parseable
	// Works out of the box with CloudWatch, Loki, or any log aggregator.
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	database.Connect()

	router := gin.Default()

	// API routes
	api := router.Group("/api")
	{
		api.GET("/skills", handlers.GetSkills)
		api.POST("/skills", handlers.CreateSkill)
		api.GET("/skills/:id", handlers.GetSkill)
		api.DELETE("/skills/:id", handlers.DeleteSkill)
		api.POST("/skills/:id/log", handlers.CreateLog)
		api.GET("/dashboard", handlers.GetDashboard)
	}

	// Health check
	router.GET("/health", handlers.HealthCheck)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	slog.Info("SkillPulse API starting", "port", port)
	if err := router.Run(":" + port); err != nil {
		slog.Error("server failed", "error", err)
		os.Exit(1)
	}
}

