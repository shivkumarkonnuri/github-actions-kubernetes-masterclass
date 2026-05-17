package main

import (
	"log/slog"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/penglongli/gin-metrics/ginmetrics"
	"github.com/trainwithshubham/skillpulse/database"
	"github.com/trainwithshubham/skillpulse/handlers"
)

func main() {
	// Structured JSON logger — every log line is machine-parseable
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	database.Connect()

	router := gin.Default()

	// ── Item 4: Prometheus metrics ──────────────────────────────────────────
	// Exposes /metrics endpoint with request count, latency histograms,
	// and error rates per endpoint — the three golden signals for a REST API.
	// Scraped by Prometheus via ServiceMonitor in k8s/60-monitoring.yaml
	m := ginmetrics.GetMonitor()
	m.SetMetricPath("/metrics")
	m.SetSlowTime(10)                        // requests > 10s are "slow"
	m.SetDuration([]float64{0.1, 0.3, 1.2, 5, 10}) // latency histogram buckets
	m.Use(router)

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
