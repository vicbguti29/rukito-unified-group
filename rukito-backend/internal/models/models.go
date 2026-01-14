package models

import (
	"encoding/json"
	"time"
)

type ColdChamber struct {
	ID                 string    `json:"id"`
	Name               string    `json:"name"`
	Content            string    `json:"content"` // Mapped from content_description in DB
	CurrentTemperature float64   `json:"current_temperature"`
	TargetTemperature  float64   `json:"target_temperature"` // From alert_config threshold_target
	RateOfChange       float64   `json:"rate_of_change"`
	Status             string    `json:"status"` // NORMAL, WARNING_HOT, CRITICAL_HOT, CRITICAL_COLD, OFFLINE
	LastUpdate         time.Time `json:"last_update"`
	IsActive           bool      `json:"is_active"`
	Location           string    `json:"location"`
	Model              string    `json:"model"`
	RecentTemps        []float64 `json:"recent_temperatures,omitempty"`
}

type TemperatureReading struct {
	ID                int       `json:"id"`
	SensorID          string    `json:"sensor_id"`
	Temperature       float64   `json:"temperature"`
	TargetTemperature float64   `json:"target_temperature"` // For historical comparison
	RateOfChange      float64   `json:"rate_of_change"`
	Timestamp         time.Time `json:"timestamp"`
	Status            string    `json:"status"` // NORMAL, WARNING_HOT, CRITICAL_HOT, CRITICAL_COLD
}

type Alert struct {
	ID            string    `json:"id"`
	SensorID      string    `json:"sensor_id"`
	Title         string    `json:"title"`
	Description   string    `json:"description"`
	Severity      string    `json:"severity"` // WARNING, CRITICAL
	Category      string    `json:"category"` // HOT_TEMP, COLD_TEMP, RAPID_CHANGE, SENSOR_OFFLINE
	Timestamp     time.Time `json:"timestamp"`
	IsRead        bool      `json:"is_read"`
	EstimatedCost float64   `json:"estimated_cost"`
	Channels      []string  `json:"channels"` // Serialized from JSON in DB
}

type Thresholds struct {
	CriticalCold float64 `json:"critical_cold"`
	Target       float64 `json:"target"`
	WarningHot   float64 `json:"warning_hot"`
	CriticalHot  float64 `json:"critical_hot"`
	RateOfChange float64 `json:"rate_of_change"`
}

type NotificationAction struct {
	Channels    []string `json:"channels"`
	TargetRoles []string `json:"target_roles"`
}

type NotificationRules struct {
	OnWarningHot  NotificationAction `json:"on_warning_hot"`
	OnCriticalHot NotificationAction `json:"on_critical_hot"`
	OnCriticalCold NotificationAction `json:"on_critical_cold"`
}

type AlertConfig struct {
	ID            string            `json:"id,omitempty"`
	SensorID      string            `json:"sensor_id"`
	Thresholds    Thresholds        `json:"thresholds"`
	Notifications NotificationRules `json:"notifications"`
	IsEnabled     bool              `json:"is_enabled"`
	UpdatedAt     time.Time         `json:"updated_at"`
}

type User struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Email       string `json:"email"`
	PhoneNumber string `json:"phone_number"`
	Role        string `json:"role"`
	AvatarURL   string `json:"avatar_url"`
}

// Helper to handle JSON fields from DB
func UnmarshalJSONField(data []byte, v interface{}) error {
	if len(data) == 0 {
		return nil
	}
	return json.Unmarshal(data, v)
}