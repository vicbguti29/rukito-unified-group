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

// GetChambers returns all cold chambers with real-time data
func GetChambers(w http.ResponseWriter, r *http.Request) {
	// Query compleja para unir metadata (chambers), configuración (target) y estado real (última lectura)
	query := `
		SELECT c.id, c.name, c.content_description, c.location, c.model, c.is_active, c.updated_at,
		       COALESCE(ac.threshold_target, 0) as target,
		       COALESCE(tr.temperature, 0) as current_temp,
		       COALESCE(tr.rate_of_change, 0) as rate,
		       COALESCE(tr.status, 'NORMAL') as status,
		       COALESCE(tr.timestamp, c.updated_at) as last_update
		FROM chambers c
		LEFT JOIN alert_configs ac ON c.id = ac.sensor_id
		LEFT JOIN (
			SELECT t1.sensor_id, t1.temperature, t1.rate_of_change, t1.status, t1.timestamp
			FROM temperature_readings t1
			JOIN (
				SELECT sensor_id, MAX(id) as max_id
				FROM temperature_readings
				GROUP BY sensor_id
			) t2 ON t1.sensor_id = t2.sensor_id AND t1.id = t2.max_id
		) tr ON c.id = tr.sensor_id
	`
	
	rows, err := db.DB.Query(query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var chambers []models.ColdChamber
	for rows.Next() {
		var c models.ColdChamber
		var contentDesc sql.NullString
		var location sql.NullString
		var model sql.NullString
		var lastUpdateStr string // Scan as string/bytes or Time depending on driver

		// Scan
		err := rows.Scan(
			&c.ID, &c.Name, &contentDesc, &location, &model, &c.IsActive, &c.LastUpdate, // updated_at from chambers (fallback)
			&c.TargetTemperature,
			&c.CurrentTemperature,
			&c.RateOfChange,
			&c.Status,
			&lastUpdateStr, // timestamp from reading
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Handle Nullables
		if contentDesc.Valid { c.Content = contentDesc.String }
		if location.Valid { c.Location = location.String }
		if model.Valid { c.Model = model.String }
		
		// Parse timestamp from DB (MySQL driver might return []byte or string)
		// Assuming the driver handles it or we parse string. 
		// For simplicity, if the driver scans into Time, we use that. 
		// If it scans into string, we parse.
		// Note: We scanned into 'lastUpdateStr' (string) for the reading timestamp.
		// Let's parse it if not empty
		if lastUpdateStr != "" {
			// Try parsing typical MySQL format
			parsedTime, err := time.Parse("2006-01-02 15:04:05", lastUpdateStr)
			if err == nil {
				c.LastUpdate = parsedTime
			}
		}

		// SUBQUERY: Obtener ultimas 180 lecturas (3 horas) para downsampling
		// Nota: Esto es N+1 queries, pero para 3 camaras es despreciable.
		recentRows, err := db.DB.Query("SELECT temperature FROM temperature_readings WHERE sensor_id = ? ORDER BY timestamp DESC LIMIT 180", c.ID)
		if err == nil {
			var temps []float64
			var rawTemps []float64
			
			// 1. Fetch raw data (reverse order: newest first)
			for recentRows.Next() {
				var t float64
				if err := recentRows.Scan(&t); err == nil {
					rawTemps = append(rawTemps, t)
				}
			}
			recentRows.Close()

			// 2. Downsampling: Take every 9th record (180 / 9 = 20 points)
			// This gives us a 3-hour trend with 20 points
			step := 9
			if len(rawTemps) < 40 {
				step = 1 // Keep all if not enough data
			}

			for i := 0; i < len(rawTemps); i += step {
				temps = append(temps, rawTemps[i])
			}

			// 3. Invertir para orden cronologico (izquierda a derecha en el grafico)
			// rawTemps was Newest -> Oldest. temps is Newest -> Oldest (subset).
			// We need Oldest -> Newest.
			for i, j := 0, len(temps)-1; i < j; i, j = i+1, j-1 {
				temps[i], temps[j] = temps[j], temps[i]
			}
			c.RecentTemps = temps
		}

		chambers = append(chambers, c)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(chambers)
}

// GetChamber returns a specific chamber by ID
func GetChamber(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	query := `
		SELECT c.id, c.name, c.content_description, c.location, c.model, c.is_active, c.updated_at,
		       COALESCE(ac.threshold_target, 0) as target,
		       COALESCE(tr.temperature, 0) as current_temp,
		       COALESCE(tr.rate_of_change, 0) as rate,
		       COALESCE(tr.status, 'NORMAL') as status,
		       COALESCE(tr.timestamp, c.updated_at) as last_update
		FROM chambers c
		LEFT JOIN alert_configs ac ON c.id = ac.sensor_id
		LEFT JOIN (
			SELECT sensor_id, temperature, rate_of_change, status, timestamp
			FROM temperature_readings
			WHERE sensor_id = ?
			ORDER BY id DESC LIMIT 1
		) tr ON c.id = tr.sensor_id
		WHERE c.id = ?
	`
	
	row := db.DB.QueryRow(query, id, id)

	var c models.ColdChamber
	var contentDesc sql.NullString
	var location sql.NullString
	var model sql.NullString
	var lastUpdateRaw []byte // Scanning into bytes to be safe

	err := row.Scan(
		&c.ID, &c.Name, &contentDesc, &location, &model, &c.IsActive, &c.LastUpdate,
		&c.TargetTemperature,
		&c.CurrentTemperature,
		&c.RateOfChange,
		&c.Status,
		&lastUpdateRaw,
	)
	
	if err == sql.ErrNoRows {
		http.Error(w, "Chamber not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if contentDesc.Valid { c.Content = contentDesc.String }
	if location.Valid { c.Location = location.String }
	if model.Valid { c.Model = model.String }
	
	if len(lastUpdateRaw) > 0 {
		// Attempt to parse standard MySQL time format
		// "2006-01-02 15:04:05"
		strVal := string(lastUpdateRaw)
		t, err := time.Parse("2006-01-02 15:04:05", strVal)
		if err == nil {
			c.LastUpdate = t
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(c)
}

// GetHealth simple health check endpoint
func GetHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":    "ok",
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

// GetUserProfile returns the profile of the current user (Hardcoded to Don Jorge for now)
func GetUserProfile(w http.ResponseWriter, r *http.Request) {
	query := `SELECT id, full_name, email, phone_number, role FROM users LIMIT 1`
	row := db.DB.QueryRow(query)

	var u models.User
	err := row.Scan(&u.ID, &u.Name, &u.Email, &u.PhoneNumber, &u.Role)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(u)
}

// UpdateUserProfile updates user data
func UpdateUserProfile(w http.ResponseWriter, r *http.Request) {
	var u models.User
	if err := json.NewDecoder(r.Body).Decode(&u); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	query := `UPDATE users SET full_name = ?, email = ?, phone_number = ? WHERE id = ?`
	_, err := db.DB.Exec(query, u.Name, u.Email, u.PhoneNumber, u.ID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(u)
}