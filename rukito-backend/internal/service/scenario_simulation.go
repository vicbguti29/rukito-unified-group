package service

import (
	"fmt"
	"time"
)

// StartScenarioSimulation inicia una simulación determinista para pruebas E2E
// CF-1: Empieza CRÍTICO -> se ARREGLA
// CF-2: Empieza NORMAL -> se VUELVE CRÍTICO
// REF-3: SIEMPRE NORMAL
func StartScenarioSimulation() {
	fmt.Println("⚠️  MODO SIMULACIÓN: ESCENARIOS ACTIVADO ⚠️")
	
	dataChannel := make(chan DataPoint, 100)

	// --- ESCENARIO 1: CF-1 (CRÍTICO -> ESTABLE) ---
	go func() {
		ticker := time.NewTicker(3 * time.Second)
		step := 0
		for range ticker.C {
			step++
			temp := -20.0
			
			// Guion:
			// Segundos 0-15 (Pasos 1-5): Temperatura alta (-16°C) -> Genera Alerta
			// Segundos 15+ (Pasos 6+):   Temperatura baja (-21°C) -> "Alguien cerró la puerta"
			if step <= 5 {
				temp = -16.0 
			} else {
				temp = -21.0
			}

			dataChannel <- DataPoint{SensorID: "CF-1", Temperature: temp, Timestamp: time.Now()}
		}
	}()

	// --- ESCENARIO 2: CF-2 (NORMAL -> CRÍTICO) ---
	go func() {
		ticker := time.NewTicker(3 * time.Second)
		step := 0
		for range ticker.C {
			step++
			temp := 4.0

			// Guion:
			// Segundos 0-21 (Pasos 1-7): Normal (4°C)
			// Segundos 21+ (Pasos 8+):   Sube a 10°C -> Falla tardía
			if step > 7 {
				temp = 10.0
			}

			dataChannel <- DataPoint{SensorID: "CF-2", Temperature: temp, Timestamp: time.Now()}
		}
	}()

	// --- ESCENARIO 3: REF-3 (CONTROL) ---
	go func() {
		ticker := time.NewTicker(3 * time.Second)
		for range ticker.C {
			// Siempre estable en 2.0°C
			dataChannel <- DataPoint{SensorID: "REF-3", Temperature: 2.0, Timestamp: time.Now()}
		}
	}()

	// Reutilizamos la MISMA lógica de procesamiento que el servicio real
	// Esto es clave para asegurar que probamos el procesador real
	go processSensorData(dataChannel)
}
