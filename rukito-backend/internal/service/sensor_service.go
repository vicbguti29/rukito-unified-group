package service

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"sync"
	"time"

	"github.com/angello/rukito-backend/internal/db"
	"github.com/google/uuid"
)

// DataPoint representa una lectura cruda de un sensor
type DataPoint struct {
	SensorID    string
	Temperature float64
	Timestamp   time.Time
}

type sensorState struct {
	temp float64
	time time.Time
}

// StartSensorSimulation inicia la simulación aleatoria normal
func StartSensorSimulation() {
	sensors := []struct {
		ID       string
		BaseTemp float64
	}{
		{"CF-1", -20.0},
		{"CF-2", 4.0},
		{"REF-3", 2.0},
	}

	dataChannel := make(chan DataPoint, 100)

	for _, s := range sensors {
		go func(id string, base float64) {
			ticker := time.NewTicker(5 * time.Second)
			currentTemp := base

			for range ticker.C {
				variation := (rand.Float64() - 0.45) * 0.5
				currentTemp += variation

				dataChannel <- DataPoint{
					SensorID:    id,
					Temperature: currentTemp,
					Timestamp:   time.Now(),
				}
			}
		}(s.ID, s.BaseTemp)
	}

	go processSensorData(dataChannel)
}

// ConfigCache para evitar consultar la BD en cada lectura del sensor
type CachedConfig struct {
	ThresholdCriticalHot  float64
	ThresholdWarningHot   float64
	ThresholdCriticalCold float64
	ActionsCriticalHot    []byte
}

var (
	configCache = make(map[string]CachedConfig)
	configMutex sync.RWMutex
)

// updateConfigCache recarga las configuraciones desde la BD periódicamente
func updateConfigCache() {
	ticker := time.NewTicker(5 * time.Second)

	for range ticker.C {
		// Consultar nuevas columnas
		query := `SELECT sensor_id, threshold_critical_hot, threshold_warning_hot, threshold_critical_cold, actions_critical_hot 
		          FROM alert_configs WHERE is_enabled = true`
		
		rows, err := db.DB.Query(query)
		if err != nil {
			fmt.Printf("Error actualizando cache de configs: %v\n", err)
			continue
		}
		
		newCache := make(map[string]CachedConfig)

		for rows.Next() {
			var id string
			var c CachedConfig
			var actionsRaw []byte

			if err := rows.Scan(&id, &c.ThresholdCriticalHot, &c.ThresholdWarningHot, &c.ThresholdCriticalCold, &actionsRaw); err == nil {
				c.ActionsCriticalHot = actionsRaw
				newCache[id] = c
			}
		}
	
rows.Close()

		configMutex.Lock()
		configCache = newCache
		configMutex.Unlock()
	}
}

func processSensorData(dataChan <-chan DataPoint) {
	// Iniciar actualizador de cache en background
	go updateConfigCache()

	lastAlertTime := make(map[string]time.Time)
	lastStates := make(map[string]sensorState)

	for dp := range dataChan {
		// 1. Calcular tasa de cambio instantánea (dT/dt)
		rateOfChange := 0.0
		if last, ok := lastStates[dp.SensorID]; ok {
			durationMinutes := dp.Timestamp.Sub(last.time).Minutes()
			if durationMinutes > 0 {
				rateOfChange = (dp.Temperature - last.temp) / durationMinutes
			}
		}
		// Guardar estado actual
		lastStates[dp.SensorID] = sensorState{temp: dp.Temperature, time: dp.Timestamp}

		// 2. Obtener límites dinámicos desde Cache
		configMutex.RLock()
		config, exists := configCache[dp.SensorID]
		configMutex.RUnlock()

		// Valores por defecto (Fallback)
		critHot := -10.0
		warnHot := -15.0
		critCold := -30.0

		if exists {
			critHot = config.ThresholdCriticalHot
			warnHot = config.ThresholdWarningHot
			critCold = config.ThresholdCriticalCold
		} else {
			// Fallback específicos hardcoded si la BD falla
			if dp.SensorID == "CF-1" { critHot = -10.0; warnHot = -15.0 }
			if dp.SensorID == "CF-2" { critHot = 10.0; warnHot = 8.0 }
		}

		// 3. Evaluar reglas dinámicamente (Lógica Granular)
		status := "NORMAL"
		severity := ""
		category := ""
		
		if dp.Temperature > critHot {
			status = "CRITICAL_HOT"
			severity = "CRITICAL"
			category = "HOT_TEMP"
		} else if dp.Temperature > warnHot {
			status = "WARNING_HOT"
			severity = "WARNING"
			category = "HOT_TEMP"
		} else if dp.Temperature < critCold {
			status = "CRITICAL_COLD"
			severity = "CRITICAL"
			category = "COLD_TEMP"
		}

		// 4. Generar Alerta si es necesario
		if severity == "CRITICAL" {
			lastTime, hasAlerted := lastAlertTime[dp.SensorID]
			// Evitar spam: solo 1 alerta cada 2 minutos
			if !hasAlerted || time.Since(lastTime) > 2*time.Minute {
				createAlert(dp, critHot, severity, category, config.ActionsCriticalHot)
				lastAlertTime[dp.SensorID] = time.Now()
			}
		}

		// 5. Persistir lectura (Con Status ENUM correcto)
		query := `
			INSERT INTO temperature_readings (sensor_id, temperature, rate_of_change, status, timestamp) 
			VALUES (?, ?, ?, ?, ?)`
		
		_, err := db.DB.Exec(query, dp.SensorID, dp.Temperature, rateOfChange, status, dp.Timestamp)
		if err != nil {
			fmt.Printf("Error DB (Readings): %v\n", err)
			continue
		}

		// 6. Actualizar timestamp en chambers (pero no status/temp pues ya no las guardamos ahí, o tal vez sí?
		// Según el nuevo handler, hacemos JOIN con la última lectura.
		// Pero es buena práctica actualizar 'updated_at' en chambers para saber que el sensor vive.
		updateQuery := `UPDATE chambers SET updated_at = ? WHERE id = ?`
		db.DB.Exec(updateQuery, dp.Timestamp, dp.SensorID)
	}
}

func createAlert(dp DataPoint, limit float64, severity string, category string, actionsJSON []byte) {
	alertID := "ALT-" + uuid.New().String()[:8]
	title := fmt.Sprintf("ALERTA: %s Excede Límite", dp.SensorID)
	desc := fmt.Sprintf("Temperatura actual: %.1f°C (Límite: %.1f°C)", dp.Temperature, limit)
	
	// Extraer canales del JSON de configuración
	// Estructura esperada en actionsJSON: {"channels": ["push", "email"], ...}
	channelsDB := []byte("[]")
	if len(actionsJSON) > 0 {
		var actionObj struct {
			Channels []string `json:"channels"`
		}
		if err := json.Unmarshal(actionsJSON, &actionObj); err == nil {
			// Re-marshal solo la lista de canales para guardar en alerts
			if b, err := json.Marshal(actionObj.Channels); err == nil {
				channelsDB = b
			}
		}
	}

	query := `
		INSERT INTO alerts (id, title, description, severity, category, sensor_id, is_read, estimated_cost, channels, timestamp)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`
	
	estCost := 0.0
	if severity == "CRITICAL" {
		estCost = 5000.0 // Simulado
	}

	_, err := db.DB.Exec(query, alertID, title, desc, severity, category, dp.SensorID, false, estCost, channelsDB, dp.Timestamp)
	if err != nil {
		fmt.Printf("Error creando alerta: %v\n", err)
	} else {
		fmt.Printf("🚨 ALERTA GENERADA: %s [%s] %.1f°C\n", dp.SensorID, severity, dp.Temperature)
	}
}