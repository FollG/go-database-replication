package rest

import (
	"context"
	"net/http"
	"time"

	"github.com/FollG/go-database-replication/internal/config"
	"github.com/FollG/go-database-replication/internal/services"
)

type Server struct {
	server             *http.Server
	userService        *services.UserService
	replicationService *services.ReplicationService
}

func NewServer(cfg config.HTTPConfig, userService *services.UserService, replicationService *services.ReplicationService) *Server {
	mux := http.NewServeMux()

	s := &Server{
		server: &http.Server{
			Addr:         ":" + cfg.Port,
			Handler:      mux,
			ReadTimeout:  10 * time.Second,
			WriteTimeout: 10 * time.Second,
			IdleTimeout:  60 * time.Second,
		},
		userService:        userService,
		replicationService: replicationService,
	}

	// Регистрация маршрутов
	s.registerRoutes(mux)

	return s
}

func (s *Server) Start() error {
	return s.server.ListenAndServe()
}

func (s *Server) Stop(ctx context.Context) error {
	return s.server.Shutdown(ctx)
}
