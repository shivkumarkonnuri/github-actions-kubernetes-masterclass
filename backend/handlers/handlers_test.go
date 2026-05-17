package handlers_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func newRouter() *gin.Engine {
	r := gin.New()
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})
	return r
}

// TestHealthCheck_Returns200 verifies the /health endpoint returns HTTP 200
// and the expected JSON body when the service is up.
func TestHealthCheck_Returns200(t *testing.T) {
	r := newRouter()

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}

	var body map[string]string
	if err := json.NewDecoder(w.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response body: %v", err)
	}
	if body["status"] != "healthy" {
		t.Errorf("expected status=healthy, got %q", body["status"])
	}
}

// TestHealthCheck_ContentType verifies the response Content-Type is JSON.
func TestHealthCheck_ContentType(t *testing.T) {
	r := newRouter()

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	ct := w.Header().Get("Content-Type")
	if !strings.HasPrefix(ct, "application/json") {
		t.Errorf("expected Content-Type application/json, got %q", ct)
	}
}

