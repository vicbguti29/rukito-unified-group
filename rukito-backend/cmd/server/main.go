package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/angello/rukito-backend/internal/api"
	"github.com/angello/rukito-backend/internal/db"
	"github.com/angello/rukito-backend/internal/service"
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Initialize Database
	db.InitDB()

	// Start Sensor Simulation (Background Worker)
	service.StartSensorSimulation()

	// Initialize Router
	r := mux.NewRouter()

	// Routes
	r.HandleFunc("/", api.GetHealth).Methods("GET")
	apiRouter := r.PathPrefix("/api").Subrouter()
	apiRouter.HandleFunc("/health", api.GetHealth).Methods("GET")
	apiRouter.HandleFunc("/chambers", api.GetChambers).Methods("GET")
	apiRouter.HandleFunc("/chambers/{id}", api.GetChamber).Methods("GET")
	apiRouter.HandleFunc("/readings/{id}", api.GetReadings).Methods("GET")
	apiRouter.HandleFunc("/readings/{id}/history", api.GetReadingHistory).Methods("GET")
	apiRouter.HandleFunc("/alerts", api.GetAlerts).Methods("GET")
	apiRouter.HandleFunc("/alerts/chamber/{id}", api.GetChamberAlerts).Methods("GET")
	apiRouter.HandleFunc("/alerts/{id}/read", api.MarkAlertRead).Methods("PATCH")
	apiRouter.HandleFunc("/config/alerts/{id}", api.GetAlertConfig).Methods("GET")
	apiRouter.HandleFunc("/config/alerts/{id}", api.UpdateAlertConfig).Methods("PUT")
	apiRouter.HandleFunc("/reports/{id}", api.GetReport).Methods("GET")
	apiRouter.HandleFunc("/statistics", api.GetStatistics).Methods("GET")
	apiRouter.HandleFunc("/users/profile", api.GetUserProfile).Methods("GET")
	apiRouter.HandleFunc("/users/profile", api.UpdateUserProfile).Methods("PUT")

	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("Rukito Backend Server Running on port %s...\n", port)

	// Global CORS Handler
	corsHandler := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")

			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusNoContent)
				return
			}

			next.ServeHTTP(w, r)
		})
	}

	if err := http.ListenAndServe(":"+port, corsHandler(r)); err != nil {
		log.Fatal(err)
	}
}
