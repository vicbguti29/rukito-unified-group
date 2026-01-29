package api

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gorilla/mux"
)

// GetReport acts as a proxy/gateway to the Python Analytics service
func GetReport(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	chamberID := vars["id"]

	startStr := r.URL.Query().Get("start")
	endStr := r.URL.Query().Get("end")
	minutes := 30 // Default

	if startStr != "" && endStr != "" {
		start, err1 := time.Parse(time.RFC3339, startStr)
		end, err2 := time.Parse(time.RFC3339, endStr)
		if err1 == nil && err2 == nil {
			diff := end.Sub(start).Minutes()
			if diff > 0 {
				minutes = int(diff)
			}
		}
	}

	pythonURL := os.Getenv("PYTHON_SERVICE_URL")
	if pythonURL == "" {
		pythonURL = "http://localhost:8000"
	}

	// Ensure we have a protocol (Render 'host' property usually omits it)
	if !strings.HasPrefix(pythonURL, "http://") && !strings.HasPrefix(pythonURL, "https://") {
		pythonURL = "http://" + pythonURL
	}

	targetURL := fmt.Sprintf("%s/analyze/report/%s?minutes=%d", pythonURL, chamberID, minutes)

	if startStr != "" && endStr != "" {
		targetURL += fmt.Sprintf("&start=%s&end=%s", startStr, endStr)
	}

	log.Printf("[V2_FINAL_STABLE] Internal Proxy: Calling Analytics at %s", targetURL)

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Get(targetURL)
	if err != nil {
		log.Printf("❌ Internal Proxy Error: Failed to connect to Analytics at %s: %v", targetURL, err)
		http.Error(w, fmt.Sprintf("Failed to connect to Analytics service: %v", err), http.StatusServiceUnavailable)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		log.Printf("❌ Internal Proxy Error: Analytics service returned status %d. Body: %s", resp.StatusCode, string(body))
		http.Error(w, fmt.Sprintf("Analytics service error (Status %d): %s", resp.StatusCode, string(body)), resp.StatusCode)
		return
	}

	log.Printf("✅ Internal Proxy Success: Received response from %s", targetURL)

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
