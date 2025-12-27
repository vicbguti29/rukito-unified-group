package models

import "time"

type ColdChamber struct {
	ID                 string    `json:"id"`
	Name               string    `json:"name"`
	Content            string    `json:"content"`
	CurrentTemperature float64   `json:"current_temperature"`
	TargetTemperature  float64   `json:"target_temperature"`
	CriticalThreshold  float64   `json:"critical_threshold"`
	WarningThreshold   float64   `json:"warning_threshold"`
	RateOfChange       float64   `json:"rate_of_change"`
	Status             int       `json:"status"` // 0=online, 1=warning, 2=offline
	LastUpdate         time.Time `json:"last_update"`
	RecentTemps        []float64 `json:"recent_temperatures"`
	IsActive           bool      `json:"is_active"`
	Location           string    `json:"location"`
}

type TemperatureReading struct {
	ID           int       `json:"id"`
	SensorID     string    `json:"sensor_id"`
	Temperature  float64   `json:"temperature"`
	TargetTemp   float64   `json:"target_temperature"`
	MinTemp      float64   `json:"min_temperature"`
	MaxTemp      float64   `json:"max_temperature"`
	RateOfChange float64   `json:"rate_of_change"`
	Timestamp    time.Time `json:"timestamp"`
	Status       string    `json:"status"` // CRÍTICO, ADVERTENCIA, NORMAL
}

type Alert struct {
	ID              string     `json:"id"`
	Title           string     `json:"title"`
	Description     string     `json:"description"`
	Priority        int        `json:"priority"` // 0=P1, 1=P2, 2=P3
	Type            int        `json:"type"`     // Enum de tipos
	SensorID        string     `json:"sensor_id"`
	Timestamp       time.Time  `json:"timestamp"`
	IsRead          bool       `json:"is_read"`
	EstimatedCost   *float64   `json:"estimated_cost"`
	AffectedContent *string    `json:"affected_content"`
	SuggestedAction *string    `json:"suggested_action"`
}

type AlertConfig struct {
	ID                    string    `json:"id"`
	SensorID              string    `json:"sensor_id"`
	MaxTemp               float64   `json:"max_temperature"`
	MinTemp               float64   `json:"min_temperature"`
	RateOfChangeThreshold float64   `json:"rate_of_change_threshold"`
	Priority              int       `json:"priority"` // 0=low, 1=med, 2=high
	IsEnabled             bool      `json:"is_enabled"`
	NotificationChannels  []string  `json:"notification_channels"`
	Recipients            []string  `json:"recipients"`
	CreatedAt             time.Time `json:"created_at"`
	UpdatedAt             time.Time `json:"updated_at"`
}
