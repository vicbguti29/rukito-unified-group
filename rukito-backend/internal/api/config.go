package api

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/angello/rukito-backend/internal/db"
	"github.com/angello/rukito-backend/internal/models"
	"github.com/gorilla/mux"
)

// GetAlertConfig returns the alert configuration for a sensor
func GetAlertConfig(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	sensorID := vars["id"]

	query := `
		SELECT sensor_id, threshold_critical_cold, threshold_target, threshold_warning_hot, threshold_critical_hot, 
		       rate_of_change_threshold, actions_warning_hot, actions_critical_hot, actions_critical_cold, 
		       is_enabled, updated_at 
		FROM alert_configs 
		WHERE sensor_id = ?`

	row := db.DB.QueryRow(query, sensorID)

	var c models.AlertConfig
	var warningHotJSON, criticalHotJSON, criticalColdJSON []byte

	err := row.Scan(
		&c.SensorID, 
		&c.Thresholds.CriticalCold, &c.Thresholds.Target, &c.Thresholds.WarningHot, &c.Thresholds.CriticalHot,
		&c.Thresholds.RateOfChange,
		&warningHotJSON, &criticalHotJSON, &criticalColdJSON,
		&c.IsEnabled, &c.UpdatedAt,
	)

	if err != nil {
		http.Error(w, "Configuration not found", http.StatusNotFound)
		return
	}

	// Parse JSON fields
	json.Unmarshal(warningHotJSON, &c.Notifications.OnWarningHot)
	json.Unmarshal(criticalHotJSON, &c.Notifications.OnCriticalHot)
	json.Unmarshal(criticalColdJSON, &c.Notifications.OnCriticalCold)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(c)
}

// UpdateAlertConfig updates the configuration
func UpdateAlertConfig(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	sensorID := vars["id"]

	var c models.AlertConfig
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// VALIDACIÓN DE NEGOCIO: Coherencia Térmica
	// Orden esperado: Critical Cold < Target < Warning Hot < Critical Hot
	t := c.Thresholds
	if t.CriticalCold >= t.Target {
		http.Error(w, "Invalid Configuration: Critical Cold must be lower than Target", http.StatusBadRequest)
		return
	}
	if t.Target >= t.WarningHot {
		http.Error(w, "Invalid Configuration: Target must be lower than Warning threshold", http.StatusBadRequest)
		return
	}
	if t.WarningHot >= t.CriticalHot {
		http.Error(w, "Invalid Configuration: Warning threshold must be lower than Critical Hot", http.StatusBadRequest)
		return
	}

	// Marshal JSON fields for DB
	warningHotJSON, _ := json.Marshal(c.Notifications.OnWarningHot)
	criticalHotJSON, _ := json.Marshal(c.Notifications.OnCriticalHot)
	criticalColdJSON, _ := json.Marshal(c.Notifications.OnCriticalCold)

	query := `
		UPDATE alert_configs 
		SET threshold_critical_cold=?, threshold_target=?, threshold_warning_hot=?, threshold_critical_hot=?, 
		    rate_of_change_threshold=?, actions_warning_hot=?, actions_critical_hot=?, actions_critical_cold=?, 
		    is_enabled=?, updated_at=NOW() 
		WHERE sensor_id=?`

	_, err := db.DB.Exec(query, 
		c.Thresholds.CriticalCold, c.Thresholds.Target, c.Thresholds.WarningHot, c.Thresholds.CriticalHot,
		c.Thresholds.RateOfChange,
		warningHotJSON, criticalHotJSON, criticalColdJSON,
		c.IsEnabled, sensorID)
	
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Return updated config
	c.SensorID = sensorID
	c.UpdatedAt = time.Now()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(c)
}