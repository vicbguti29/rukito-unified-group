package api

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"github.com/angello/rukito-backend/internal/db"
	"github.com/angello/rukito-backend/internal/models"
	"github.com/gorilla/mux"
)

// GetChambers returns all cold chambers from the database
func GetChambers(w http.ResponseWriter, r *http.Request) {
	query := `SELECT id, name, content, target_temperature, critical_threshold, warning_threshold, location, is_active, updated_at FROM chambers`
	rows, err := db.DB.Query(query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var chambers []models.ColdChamber
	for rows.Next() {
		var c models.ColdChamber
		err := rows.Scan(&c.ID, &c.Name, &c.Content, &c.TargetTemperature, &c.CriticalThreshold, &c.WarningThreshold, &c.Location, &c.IsActive, &c.LastUpdate)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// En un sistema real, aquí buscaríamos la temperatura actual y lecturas recientes
		// Por ahora simularemos datos básicos o dejaremos valores por defecto
		c.CurrentTemperature = c.TargetTemperature // Placeholder
		c.Status = 0 // Online
		c.RecentTemps = []float64{c.TargetTemperature, c.TargetTemperature}

		chambers = append(chambers, c)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(chambers)
}

// GetChamber returns a specific chamber by ID
func GetChamber(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	query := `SELECT id, name, content, target_temperature, critical_threshold, warning_threshold, location, is_active, updated_at FROM chambers WHERE id = ?`
	row := db.DB.QueryRow(query, id)

	var c models.ColdChamber
	err := row.Scan(&c.ID, &c.Name, &c.Content, &c.TargetTemperature, &c.CriticalThreshold, &c.WarningThreshold, &c.Location, &c.IsActive, &c.LastUpdate)
	
	if err == sql.ErrNoRows {
		http.Error(w, "Chamber not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Simulando datos dinámicos por ahora
	c.CurrentTemperature = c.TargetTemperature
	c.Status = 0
	c.RecentTemps = []float64{c.TargetTemperature, c.TargetTemperature}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(c)
}

// GetHealth simple health check endpoint
func GetHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":    "ok",
		"timestamp": "2024-12-11T22:30:00Z", // Placeholder
	})
}
