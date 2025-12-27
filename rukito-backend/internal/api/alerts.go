package api

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/angello/rukito-backend/internal/db"
	"github.com/angello/rukito-backend/internal/models"
	"github.com/gorilla/mux"
)

// GetAlerts returns all alerts with optional filtering
// Query Params: limit, unread_only (bool)
func GetAlerts(w http.ResponseWriter, r *http.Request) {
	limitStr := r.URL.Query().Get("limit")
	unreadOnlyStr := r.URL.Query().Get("unread_only")

	limit := 50
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	query := `SELECT id, title, description, priority, type, sensor_id, is_read, estimated_cost, timestamp FROM alerts`
	var args []interface{}

	if unreadOnlyStr == "true" {
		query += ` WHERE is_read = FALSE`
	}

	query += ` ORDER BY timestamp DESC LIMIT ?`
	args = append(args, limit)

	rows, err := db.DB.Query(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var alerts []models.Alert
	for rows.Next() {
		var a models.Alert
		// Handling nullable EstimatedCost
		var estCost sql.NullFloat64
		
		err := rows.Scan(&a.ID, &a.Title, &a.Description, &a.Priority, &a.Type, &a.SensorID, &a.IsRead, &estCost, &a.Timestamp)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if estCost.Valid {
			val := estCost.Float64
			a.EstimatedCost = &val
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
		SELECT id, title, description, priority, type, sensor_id, is_read, estimated_cost, timestamp 
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

		err := rows.Scan(&a.ID, &a.Title, &a.Description, &a.Priority, &a.Type, &a.SensorID, &a.IsRead, &estCost, &a.Timestamp)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if estCost.Valid {
			val := estCost.Float64
			a.EstimatedCost = &val
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

	response := map[string]interface{}{
		"id":         alertID,
		"is_read":    true,
		"updated_at": time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
