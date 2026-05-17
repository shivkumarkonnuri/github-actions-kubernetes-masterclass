package database

import (
	"database/sql"
	"fmt"
	"log/slog"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

func Connect() {
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "3306")
	user := getEnv("DB_USER", "skillpulse")
	password := getEnv("DB_PASSWORD", "skillpulse123")
	dbname := getEnv("DB_NAME", "skillpulse")

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true", user, password, host, port, dbname)

	var err error
	for i := 0; i < 30; i++ {
		DB, err = sql.Open("mysql", dsn)
		if err == nil {
			err = DB.Ping()
			if err == nil {
				slog.Info("connected to MySQL database", "host", host, "port", port, "db", dbname)
				DB.SetMaxOpenConns(10)
				DB.SetMaxIdleConns(5)
				DB.SetConnMaxLifetime(5 * time.Minute)
				return
			}
		}
		slog.Warn("waiting for database", "attempt", i+1, "max", 30, "error", err)
		time.Sleep(2 * time.Second)
	}

	slog.Error("could not connect to database", "error", err)
	os.Exit(1)
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

