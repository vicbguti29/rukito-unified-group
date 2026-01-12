package api

import (
	"encoding/json"
	"fmt"
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
		SELECT id, sensor_id, max_temperature, min_temperature, rate_of_change_threshold, priority, is_enabled, notification_channels, recipients, created_at, updated_at 
		FROM alert_configs 
		WHERE sensor_id = ?`

	row := db.DB.QueryRow(query, sensorID)

	var c models.AlertConfig
	var channelsJSON, recipientsJSON []byte

	err := row.Scan(&c.ID, &c.SensorID, &c.MaxTemp, &c.MinTemp, &c.RateOfChangeThreshold, &c.Priority, &c.IsEnabled, &channelsJSON, &recipientsJSON, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		// If not found, return a default config or 404. Ideally we should create a default one.
		// For now returning 404 to be safe.
		http.Error(w, "Configuration not found", http.StatusNotFound)
		return
	}

	// Parse JSON fields
	json.Unmarshal(channelsJSON, &c.NotificationChannels)
	json.Unmarshal(recipientsJSON, &c.Recipients)

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

	// Marshall JSON fields for DB
	channelsJSON, _ := json.Marshal(c.NotificationChannels)
	recipientsJSON, _ := json.Marshal(c.Recipients)

	query := `
		UPDATE alert_configs 
		SET max_temperature=?, min_temperature=?, rate_of_change_threshold=?, priority=?, is_enabled=?, notification_channels=?, recipients=?, updated_at=NOW() 
		WHERE sensor_id=?`

	_, err := db.DB.Exec(query, c.MaxTemp, c.MinTemp, c.RateOfChangeThreshold, c.Priority, c.IsEnabled, channelsJSON, recipientsJSON, sensorID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// SINCRONIZACIÓN: Actualizar también los umbrales visuales en la tabla 'chambers'
	// Asumimos lógica por defecto: Advertencia es 2 grados antes del crítico
	updateChamberQuery := `
		UPDATE chambers 
		SET critical_threshold = ?, warning_threshold = ? 
		WHERE id = ?`
	
	// Warning threshold = MaxTemp - 2.0 (ej: si Max es -18, Warning es -20)
	// Nota: Para cámaras de frío, "más caliente" es peor, así que warning debe ser MENOR que critical
	warningThreshold := c.MaxTemp - 2.0
	
	_, err = db.DB.Exec(updateChamberQuery, c.MaxTemp, warningThreshold, sensorID)
	if err != nil {
		// Logueamos el error pero no fallamos la request principal
		fmt.Printf("Warning: Failed to sync chamber thresholds: %v\n", err)
	}

	// Return updated config (fetching it again to be sure)
	// For simplicity, we just return what we received + updated timestamp
	c.SensorID = sensorID
	c.UpdatedAt = time.Now()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(c)
}
