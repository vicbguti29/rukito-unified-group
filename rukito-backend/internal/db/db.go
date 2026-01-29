package db

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

// InitDB initializes the database connection using environment variables
func InitDB() {
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")

	// DSN (Data Source Name)
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&tls=skip-verify", dbUser, dbPassword, dbHost, dbPort, dbName)

	var err error
	DB, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Printf("Warning: Error opening DB connection: %v. Retrying...", err)
	}

	// Retry logic for cloud environments
	maxRetries := 5
	for i := 0; i < maxRetries; i++ {
		fmt.Printf("Connecting to DB (Attempt %d/%d)...\n", i+1, maxRetries)
		err = DB.Ping()
		if err == nil {
			fmt.Println("✅ Successfully connected to MySQL database")
			return
		}
		log.Printf("❌ Connection attempt failed: %v. Waiting 5s before next attempt...", err)
		time.Sleep(5 * time.Second)
	}

	log.Println("⚠️ Final warning: Could not verify DB connection after several attempts. Server will start anyway to provide health signals.")
}

// GetDB returns the database instance
func GetDB() *sql.DB {
	return DB
}
