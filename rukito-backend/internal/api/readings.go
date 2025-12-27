package api

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/angello/rukito-backend/internal/db"
	"github.com/angello/rukito-backend/internal/models"
	"github.com/gorilla/mux"
)

// GetReadings returns recent readings for a chamber
// Query Params: limit (default 100)
func GetReadings(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	sensorID := vars["id"]

	limitStr := r.URL.Query().Get("limit")
	limit := 100
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	query := `
		SELECT id, sensor_id, temperature, rate_of_change, status, timestamp 
		FROM temperature_readings 
		WHERE sensor_id = ? 
		ORDER BY timestamp DESC 
		LIMIT ?`

	rows, err := db.DB.Query(query, sensorID, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var readings []models.TemperatureReading
	for rows.Next() {
		var tr models.TemperatureReading
		// Note: The struct has TargetTemp, MinTemp, MaxTemp which are not in the readings table
		// based on the SQL script. We might need to join with chambers table or leave them 0/null
		// For now, we will fill what we have in the DB.
		// The API Spec response shows them. Ideally, we JOIN chambers to get targets.
		
		err := rows.Scan(&tr.ID, &tr.SensorID, &tr.Temperature, &tr.RateOfChange, &tr.Status, &tr.Timestamp)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		readings = append(readings, tr)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(readings)
}

// GetReadingHistory returns historical readings for a date range
// Query Params: start, end (ISO8601)
func GetReadingHistory(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	sensorID := vars["id"]

	startStr := r.URL.Query().Get("start")
	endStr := r.URL.Query().Get("end")

	if startStr == "" || endStr == "" {
		http.Error(w, "Missing 'start' or 'end' query parameters", http.StatusBadRequest)
		return
	}

	// Validate time format (RFC3339 matches ISO8601 for this purpose)
	_, errStart := time.Parse(time.RFC3339, startStr)
	_, errEnd := time.Parse(time.RFC3339, endStr)

	if errStart != nil || errEnd != nil {
		http.Error(w, "Invalid date format. Use ISO8601 (e.g. 2024-12-01T00:00:00Z)", http.StatusBadRequest)
		return
	}

	query := `
		SELECT id, sensor_id, temperature, rate_of_change, status, timestamp 
		FROM temperature_readings 
		WHERE sensor_id = ? AND timestamp BETWEEN ? AND ?
		ORDER BY timestamp ASC`

	rows, err := db.DB.Query(query, sensorID, startStr, endStr)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var readings []models.TemperatureReading
	for rows.Next() {
		var tr models.TemperatureReading
		err := rows.Scan(&tr.ID, &tr.SensorID, &tr.Temperature, &tr.RateOfChange, &tr.Status, &tr.Timestamp)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		readings = append(readings, tr)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(readings)
}
