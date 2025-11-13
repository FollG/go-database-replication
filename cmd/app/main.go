package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/FollG/go-database-replication/internal/app"
)

// Version information set during build
var (
	version   = "dev"
	buildTime = "unknown"
)

func main() {
	versionFlag := flag.Bool("version", false, "Print version information")
	flag.Parse()

	if *versionFlag {
		fmt.Printf("MySQL Replication App\n")
		fmt.Printf("Version: %s\n", version)
		fmt.Printf("Build Time: %s\n", buildTime)
		os.Exit(0)
	}

	// Инициализация и запуск приложения
	if err := app.Run(); err != nil {
		log.Fatalf("Failed to start application: %v", err)
	}
}
