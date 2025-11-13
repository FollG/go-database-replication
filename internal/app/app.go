package app

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/FollG/go-database-replication/internal/config"
	"github.com/FollG/go-database-replication/internal/database/mysql"
	"github.com/FollG/go-database-replication/internal/services"
	"github.com/FollG/go-database-replication/internal/transport/rest"
)

func Run() error {
	// Загрузка конфигурации
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	// Инициализация базы данных
	db, err := mysql.NewConnection(cfg.Database)
	if err != nil {
		return err
	}
	defer db.Close()

	// Инициализация сервисов
	userService := services.NewUserService(db)
	replicationService := services.NewReplicationService(db)

	// Инициализация HTTP сервера
	server := rest.NewServer(cfg.HTTP, userService, replicationService)

	// Запуск сервера в горутине
	go func() {
		log.Printf("Starting server on port %s", cfg.HTTP.Port)
		if err := server.Start(); err != nil {
			log.Printf("Server error: %v", err)
		}
	}()

	// Ожидание сигнала для graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Stop(ctx); err != nil {
		return err
	}

	log.Println("Server exited properly")
	return nil
}
