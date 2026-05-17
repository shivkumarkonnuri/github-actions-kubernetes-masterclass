package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/penglongli/gin-metrics/ginmetrics"
	"github.com/trainwithshubham/skillpulse/database"
	"github.com/trainwithshubham/skillpulse/handlers"
)

func main() {
	// Structured JSON logger — every log line is machine-parseable by Loki / CloudWatch
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	database.Connect()

	router := gin.Default()

	// ── Prometheus metrics ────────────────────────────────────────────────────
	// Exposes /metrics with request count, latency histograms, and error rates.
	// Scraped by Prometheus via ServiceMonitor in k8s/60-monitoring.yaml.
	m := ginmetrics.GetMonitor()
	m.SetMetricPath("/metrics")
	m.SetSlowTime(10)                             // requests > 10s are "slow"
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

	// Health check — used by liveness, readiness, and startupProbe
	router.GET("/health", handlers.HealthCheck)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// ── Graceful shutdown ─────────────────────────────────────────────────────
	// Kubernetes sends SIGTERM before killing the pod. We catch it, stop
	// accepting new connections, and drain in-flight requests within 30s.
	// terminationGracePeriodSeconds: 35 in the Deployment gives a 5s buffer.
	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// Start server in a goroutine so the main goroutine can listen for signals
	go func() {
		slog.Info("SkillPulse API starting", "port", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("server failed to start", "error", err)
			os.Exit(1)
		}
	}()

	// Wait for SIGINT (Ctrl+C locally) or SIGTERM (Kubernetes pod eviction / rolling update)
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	sig := <-quit

	slog.Info("shutdown signal received — draining connections", "signal", sig.String())

	// Give in-flight requests up to 30s to complete
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		slog.Error("forced shutdown after timeout", "error", err)
		os.Exit(1)
	}

	slog.Info("server stopped cleanly")
}
