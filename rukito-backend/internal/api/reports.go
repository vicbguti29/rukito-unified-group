package api

import (
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/gorilla/mux"
)

// GetReport acts as a proxy/gateway to the Python Analytics service
func GetReport(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chamberID := vars["id"]

	pythonURL := os.Getenv("PYTHON_SERVICE_URL")
	if pythonURL == "" {
		pythonURL = "http://localhost:8000"
	}

	targetURL := fmt.Sprintf("%s/analyze/report/%s", pythonURL, chamberID)

	fmt.Printf("Go Backend: Requesting report from Python service at %s\n", targetURL)

	resp, err := http.Get(targetURL)
	if err != nil {
		http.Error(w, "Failed to connect to Analytics service: "+err.Error(), http.StatusServiceUnavailable)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		http.Error(w, fmt.Sprintf("Analytics service error: %s", string(body)), resp.StatusCode)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	io.Copy(w, resp.Body)
}

// GetStatistics acts as a proxy for global statistics from Python service
func GetStatistics(w http.ResponseWriter, r *http.Request) {
	pythonURL := os.Getenv("PYTHON_SERVICE_URL")
	if pythonURL == "" {
		pythonURL = "http://localhost:8000"
	}

	targetURL := fmt.Sprintf("%s/analyze/statistics", pythonURL)

	resp, err := http.Get(targetURL)
	if err != nil {
		http.Error(w, "Failed to connect to Analytics service", http.StatusServiceUnavailable)
		return
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", "application/json")
	io.Copy(w, resp.Body)
}