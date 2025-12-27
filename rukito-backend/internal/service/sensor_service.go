package service

import (
	"fmt"
	"math/rand"
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

func processSensorData(dataChan <-chan DataPoint) {
	fmt.Println("Worker Pool: Procesando flujo de datos...")

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
		// Guardar estado actual para la próxima lectura
		lastStates[dp.SensorID] = sensorState{temp: dp.Temperature, time: dp.Timestamp}

		status := "NORMAL"
		isCritical := false
		
		if dp.SensorID == "CF-1" && dp.Temperature > -18.0 {
			status = "CRÍTICO"
			isCritical = true
		} else if dp.SensorID == "CF-2" && dp.Temperature > 8.0 {
			status = "CRÍTICO"
			isCritical = true
		} else if dp.SensorID == "CF-1" && dp.Temperature > -19.0 {
			status = "ADVERTENCIA"
		}

		if isCritical {
			lastTime, exists := lastAlertTime[dp.SensorID]
			// En modo normal, alerta cada 2 minutos
			if !exists || time.Since(lastTime) > 2*time.Minute {
				createAlert(dp)
				lastAlertTime[dp.SensorID] = time.Now()
			}
		}

		query := `
			INSERT INTO temperature_readings (sensor_id, temperature, rate_of_change, status, timestamp) 
			VALUES (?, ?, ?, ?, ?)`
		
		_, err := db.DB.Exec(query, dp.SensorID, dp.Temperature, rateOfChange, status, dp.Timestamp)
		if err != nil {
			fmt.Printf("Error DB: %v\n", err)
			continue
		}

		// Actualizar cámara
		chamberStatus := 0
		if status != "NORMAL" {
			chamberStatus = 1
		}
		
		updateQuery := `UPDATE chambers SET updated_at = ?, current_temperature = ?, status = ?, rate_of_change = ? WHERE id = ?`
		db.DB.Exec(updateQuery, dp.Timestamp, dp.Temperature, chamberStatus, rateOfChange, dp.SensorID)
	}
}

func createAlert(dp DataPoint) {
	alertID := "ALT-" + uuid.New().String()[:8]
	title := fmt.Sprintf("ALERTA CRÍTICA: %s", dp.SensorID)
	desc := fmt.Sprintf("Temperatura crítica: %.1f°C", dp.Temperature)
	
	query := `
		INSERT INTO alerts (id, title, description, priority, type, sensor_id, is_read, estimated_cost, timestamp)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		`
	
	estCost := 0.0
	if dp.SensorID == "CF-1" {
		estCost = 15000.0
	}

	db.DB.Exec(query, alertID, title, desc, 0, 0, dp.SensorID, false, estCost, dp.Timestamp)
	fmt.Printf("🚨 ALERTA CREADA: %s (%.1f°C)\n", dp.SensorID, dp.Temperature)
}