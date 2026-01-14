package api

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/angello/rukito-backend/internal/db"
	"github.com/angello/rukito-backend/internal/models"
	"github.com/gorilla/mux"
)

// GetAlerts returns all alerts with optional filtering
func GetAlerts(w http.ResponseWriter, r *http.Request) {
	// Query params handling could be added here (limit, severity, etc.)
	
	query := `
		SELECT id, title, COALESCE(description, ''), severity, category, sensor_id, is_read, estimated_cost, channels, timestamp 
		FROM alerts 
		ORDER BY timestamp DESC 
		LIMIT 50`

	rows, err := db.DB.Query(query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var alerts []models.Alert
	for rows.Next() {
		var a models.Alert
		var estCost sql.NullFloat64
		var channelsJSON []byte

		// "El Cuidado Especial": Leemos channels como []byte (channelsJSON)
		err := rows.Scan(&a.ID, &a.Title, &a.Description, &a.Severity, &a.Category, &a.SensorID, &a.IsRead, &estCost, &channelsJSON, &a.Timestamp)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if estCost.Valid {
			a.EstimatedCost = estCost.Float64
		}

		// Deserializamos: De Bytes a []string
		if len(channelsJSON) > 0 {
			json.Unmarshal(channelsJSON, &a.Channels)
		} else {
			a.Channels = []string{} // Evitar null en el JSON de respuesta
		}

		alerts = append(alerts, a)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(alerts)
}

// GetChamberAlerts returns alerts for a specific chamber
func GetChamberAlerts(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	sensorID := vars["id"]

	query := `
		SELECT id, title, COALESCE(description, ''), severity, category, sensor_id, is_read, estimated_cost, channels, timestamp 
		FROM alerts 
		WHERE sensor_id = ? 
		ORDER BY timestamp DESC 
		LIMIT 50`

	rows, err := db.DB.Query(query, sensorID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var alerts []models.Alert
	for rows.Next() {
		var a models.Alert
		var estCost sql.NullFloat64
		var channelsJSON []byte

		err := rows.Scan(&a.ID, &a.Title, &a.Description, &a.Severity, &a.Category, &a.SensorID, &a.IsRead, &estCost, &channelsJSON, &a.Timestamp)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if estCost.Valid {
			a.EstimatedCost = estCost.Float64
		}

		if len(channelsJSON) > 0 {
			json.Unmarshal(channelsJSON, &a.Channels)
		} else {
			a.Channels = []string{}
		}

		alerts = append(alerts, a)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(alerts)
}

// MarkAlertRead marks an alert as read
func MarkAlertRead(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	alertID := vars["id"]

	query := `UPDATE alerts SET is_read = TRUE WHERE id = ?`
	_, err := db.DB.Exec(query, alertID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Retornamos el objeto actualizado (mockeado parcialmente para rapidez)
	response := map[string]interface{}{
		"id":         alertID,
		"is_read":    true,
		"updated_at": time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}