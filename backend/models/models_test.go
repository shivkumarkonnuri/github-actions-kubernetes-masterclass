package models_test

import (
	"testing"

	"github.com/trainwithshubham/skillpulse/models"
)

// TestCreateSkillRequest_Fields verifies the struct fields are mapped correctly.
func TestCreateSkillRequest_Fields(t *testing.T) {
	req := models.CreateSkillRequest{
		Name:        "Kubernetes",
		Category:    "DevOps",
		TargetHours: 60,
	}

	if req.Name != "Kubernetes" {
		t.Errorf("expected Name=Kubernetes, got %q", req.Name)
	}
	if req.Category != "DevOps" {
		t.Errorf("expected Category=DevOps, got %q", req.Category)
	}
	if req.TargetHours != 60 {
		t.Errorf("expected TargetHours=60, got %d", req.TargetHours)
	}
}

// TestCreateLogRequest_Fields verifies log request fields are mapped correctly.
func TestCreateLogRequest_Fields(t *testing.T) {
	req := models.CreateLogRequest{
		Hours:   2.5,
		Notes:   "Practiced deployments",
		LogDate: "2026-05-17",
	}

	if req.Hours != 2.5 {
		t.Errorf("expected Hours=2.5, got %f", req.Hours)
	}
	if req.LogDate != "2026-05-17" {
		t.Errorf("expected LogDate=2026-05-17, got %q", req.LogDate)
	}
}

// TestSkill_ProgressPercent verifies progress calculation logic.
func TestSkill_ProgressPercent(t *testing.T) {
	cases := []struct {
		name        string
		totalHours  float64
		targetHours int
		wantPct     float64
	}{
		{"zero target", 5, 0, 0},
		{"half done", 25, 50, 50},
		{"over target", 60, 50, 100},
		{"exact", 50, 50, 100},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			s := models.Skill{
				TotalHours:  tc.totalHours,
				TargetHours: tc.targetHours,
			}
			got := s.ProgressPercent()
			if got != tc.wantPct {
				t.Errorf("ProgressPercent()=%v, want %v", got, tc.wantPct)
			}
		})
	}
}

