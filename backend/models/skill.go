package models

import "time"

type Skill struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Category    string    `json:"category"`
	TargetHours int       `json:"target_hours"`
	TotalHours  float64   `json:"total_hours"`
	CreatedAt   time.Time `json:"created_at"`
}

// ProgressPercent returns how far along (0-100) the skill is toward its target.
// Returns 0 if TargetHours is not set; caps at 100 if already exceeded.
func (s Skill) ProgressPercent() float64 {
	if s.TargetHours <= 0 {
		return 0
	}
	pct := (s.TotalHours / float64(s.TargetHours)) * 100
	if pct > 100 {
		return 100
	}
	return pct
}

type CreateSkillRequest struct {
	Name        string `json:"name" binding:"required"`
	Category    string `json:"category"`
	TargetHours int    `json:"target_hours"`
}

type LearningLog struct {
	ID        int       `json:"id"`
	SkillID   int       `json:"skill_id"`
	Hours     float64   `json:"hours"`
	Notes     string    `json:"notes"`
	LogDate   string    `json:"log_date"`
	CreatedAt time.Time `json:"created_at"`
}

type CreateLogRequest struct {
	Hours   float64 `json:"hours" binding:"required"`
	Notes   string  `json:"notes"`
	LogDate string  `json:"log_date" binding:"required"`
}

type Dashboard struct {
	TotalSkills int     `json:"total_skills"`
	TotalHours  float64 `json:"total_hours"`
	TotalLogs   int     `json:"total_logs"`
	TopSkill    string  `json:"top_skill"`
}

