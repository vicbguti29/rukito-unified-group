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

	// Unimos con alert_configs para obtener el target_temperature histórico (aproximado, usando el actual)
	// En un sistema ideal, el target debería guardarse en cada lectura si cambia mucho, 
	// pero para este MVP usamos el actual de la configuración.
	query := `
		SELECT tr.id, tr.sensor_id, tr.temperature, tr.rate_of_change, tr.status, tr.timestamp,
		       COALESCE(ac.threshold_target, 0)
		FROM temperature_readings tr
		LEFT JOIN alert_configs ac ON tr.sensor_id = ac.sensor_id
		WHERE tr.sensor_id = ? 
		ORDER BY tr.timestamp DESC 
		LIMIT ?`

	rows, err := db.DB.Query(query, sensorID, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	readings := []models.TemperatureReading{}
	for rows.Next() {
		var tr models.TemperatureReading
		var timestampBytes []byte 

		// Scan into temporary bytes for timestamp just in case
		err := rows.Scan(&tr.ID, &tr.SensorID, &tr.Temperature, &tr.RateOfChange, &tr.Status, &timestampBytes, &tr.TargetTemperature)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if len(timestampBytes) > 0 {
			// Try parsing standard MySQL format
			t, err := time.Parse("2006-01-02 15:04:05", string(timestampBytes))
			if err == nil {
				tr.Timestamp = t
			} else {
				// Fallback or try RFC3339 if stored differently
				tr.Timestamp, _ = time.Parse(time.RFC3339, string(timestampBytes))
			}
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

	// Validate time format
	// El frontend envía ISO8601 (2024-01-01T00:00:00Z)
	startParams, errStart := time.Parse(time.RFC3339, startStr)
	endParams, errEnd := time.Parse(time.RFC3339, endStr)

	// Si falla, probar formato simple sin Z
	if errStart != nil {
		startParams, errStart = time.Parse("2006-01-02T15:04:05", startStr)
	}
	if errEnd != nil {
		endParams, errEnd = time.Parse("2006-01-02T15:04:05", endStr)
	}

	if errStart != nil || errEnd != nil {
		http.Error(w, "Invalid date format. Use ISO8601 (e.g. 2024-12-01T00:00:00Z)", http.StatusBadRequest)
		return
	}

	query := `
		SELECT tr.id, tr.sensor_id, tr.temperature, tr.rate_of_change, tr.status, tr.timestamp,
		       COALESCE(ac.threshold_target, 0)
		FROM temperature_readings tr
		LEFT JOIN alert_configs ac ON tr.sensor_id = ac.sensor_id
		WHERE tr.sensor_id = ? AND tr.timestamp BETWEEN ? AND ?
		ORDER BY tr.timestamp ASC`

	// MySQL driver accepts time.Time objects
	rows, err := db.DB.Query(query, sensorID, startParams, endParams)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	readings := []models.TemperatureReading{}
	var rawReadings []models.TemperatureReading

	for rows.Next() {
		var tr models.TemperatureReading
		var timestampBytes []byte

		err := rows.Scan(&tr.ID, &tr.SensorID, &tr.Temperature, &tr.RateOfChange, &tr.Status, &timestampBytes, &tr.TargetTemperature)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if len(timestampBytes) > 0 {
			t, err := time.Parse("2006-01-02 15:04:05", string(timestampBytes))
			if err == nil {
				tr.Timestamp = t
			} else {
				tr.Timestamp, _ = time.Parse(time.RFC3339, string(timestampBytes))
			}
		}

		rawReadings = append(rawReadings, tr)
	}
	
	// Downsampling Logic (AVERAGE)
	// Target: ~100 points maximum for clear visualization (High Resolution Smooth)
	const targetPoints = 100
	totalCount := len(rawReadings)
	
	if totalCount <= targetPoints {
		readings = rawReadings
	} else {
		step := totalCount / targetPoints
		if step < 1 { step = 1 }
		
		for i := 0; i < totalCount; i += step {
			end := i + step
			if end > totalCount {
				end = totalCount
			}

			// Calculate Average for this chunk
			var sumTemp float64
			var count int
			
			// Track max severity in this chunk for status
			// We want the status to reflect the worst case in the chunk, even if we average the temp
			worstStatus := "NORMAL"
			
			for j := i; j < end; j++ {
				sumTemp += rawReadings[j].Temperature
				count++
				
				// Basic priority check for status (Critical > Warning > Normal)
				currentStatus := rawReadings[j].Status
				if currentStatus == "CRITICAL_HOT" || currentStatus == "CRITICAL_COLD" {
					worstStatus = currentStatus
				} else if (currentStatus == "WARNING_HOT" || currentStatus == "WARNING_COLD") && worstStatus == "NORMAL" {
					worstStatus = currentStatus
				}
			}

			if count > 0 {
				avgTemp := sumTemp / float64(count)
				
				// Create a representative reading
				// We use the timestamp of the middle of the chunk for better alignment
				midIndex := i + (count / 2)
				repReading := rawReadings[midIndex]
				
				repReading.Temperature = avgTemp
				repReading.Status = worstStatus // Preserve the worst status of the block
				
				readings = append(readings, repReading)
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(readings)
}