package service

import (
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
	fmt.Println("🚀 MODO SIMULACIÓN: RANDOM (REALISTA) ACTIVADO")

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

var (

	configCache = make(map[string]struct {

		MaxTemp float64

		MinTemp float64

	})

	configMutex sync.RWMutex

)



// updateConfigCache recarga las configuraciones desde la BD periódicamente

func updateConfigCache() {

	ticker := time.NewTicker(5 * time.Second)

	for range ticker.C {

		rows, err := db.DB.Query("SELECT sensor_id, max_temperature, min_temperature FROM alert_configs WHERE is_enabled = true")

		if err != nil {

			fmt.Printf("Error actualizando cache de configs: %v\n", err)

			continue

		}

		

		newCache := make(map[string]struct {

			MaxTemp float64

			MinTemp float64

		})



		for rows.Next() {

			var id string

			var max, min float64

			if err := rows.Scan(&id, &max, &min); err == nil {

				newCache[id] = struct{MaxTemp float64; MinTemp float64}{max, min}

			}

		}

		rows.Close()



		configMutex.Lock()

		configCache = newCache

		configMutex.Unlock()

	}

}



func processSensorData(dataChan <-chan DataPoint) {

	fmt.Println("Worker Pool: Procesando flujo de datos (Dinámico)...")



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



		// Valores por defecto si no hay config (Fallback seguro)

		maxTemp := -10.0 // Valor alto por seguridad

		if !exists {

			// Valores hardcoded SOLO como fallback de emergencia

			if dp.SensorID == "CF-1" { maxTemp = -18.0 }

			if dp.SensorID == "CF-2" { maxTemp = 8.0 }

			if dp.SensorID == "REF-3" { maxTemp = 5.0 }

		} else {

			maxTemp = config.MaxTemp

		}



		status := "NORMAL"

		isCritical := false

		

		// 3. Evaluar reglas dinámicamente

		if dp.Temperature > maxTemp {

			status = "CRÍTICO"

			isCritical = true

		} else if dp.Temperature > (maxTemp - 1.0) {

			// Zona de advertencia automática (1 grado antes del límite)

			status = "ADVERTENCIA"

		}



		// 4. Generar Alerta si es necesario

		if isCritical {

			lastTime, hasAlerted := lastAlertTime[dp.SensorID]

			// Evitar spam: solo 1 alerta cada 2 minutos

			if !hasAlerted || time.Since(lastTime) > 2*time.Minute {

				createAlert(dp, maxTemp)

				lastAlertTime[dp.SensorID] = time.Now()

			}

		}



		// 5. Persistir lectura

		query := `

			INSERT INTO temperature_readings (sensor_id, temperature, rate_of_change, status, timestamp) 

			VALUES (?, ?, ?, ?, ?)`

		

		_, err := db.DB.Exec(query, dp.SensorID, dp.Temperature, rateOfChange, status, dp.Timestamp)

		if err != nil {

			fmt.Printf("Error DB: %v\n", err)

			continue

		}



		// 6. Actualizar estado en tiempo real de la cámara

		chamberStatus := 0 // Online

		if status == "ADVERTENCIA" { chamberStatus = 1 }

		if status == "CRÍTICO" { chamberStatus = 1 } // Warning visual para crítico también

		

		updateQuery := `UPDATE chambers SET updated_at = ?, current_temperature = ?, status = ?, rate_of_change = ? WHERE id = ?`

		db.DB.Exec(updateQuery, dp.Timestamp, dp.Temperature, chamberStatus, rateOfChange, dp.SensorID)

	}

}



func createAlert(dp DataPoint, threshold float64) {

	alertID := "ALT-" + uuid.New().String()[:8]

	title := fmt.Sprintf("ALERTA: %s Excede Límite", dp.SensorID)

	desc := fmt.Sprintf("Temperatura actual: %.1f°C (Límite configurado: %.1f°C)", dp.Temperature, threshold)

	

	query := `

		INSERT INTO alerts (id, title, description, priority, type, sensor_id, is_read, estimated_cost, timestamp)

		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)

		`

	

	estCost := 0.0

	// Costo simulado solo para demo

	if dp.SensorID == "CF-1" {

		estCost = 15000.0

	}



	// Priority 0 = Crítica

	db.DB.Exec(query, alertID, title, desc, 0, 0, dp.SensorID, false, estCost, dp.Timestamp)

	fmt.Printf("🚨 ALERTA DINÁMICA: %s (%.1f > %.1f)\n", dp.SensorID, dp.Temperature, threshold)

}
