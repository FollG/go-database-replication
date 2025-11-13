package rest

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/FollG/go-database-replication/internal/models"
)

func (s *Server) registerRoutes(mux *http.ServeMux) {
	// Users endpoints
	mux.HandleFunc("GET /health", s.healthCheck)
	mux.HandleFunc("GET /api/users", s.listUsers)
	mux.HandleFunc("POST /api/users", s.createUser)
	mux.HandleFunc("GET /api/users/{id}", s.getUser)

	// Replication monitoring
	mux.HandleFunc("GET /api/replication/status", s.getReplicationStatus)
	mux.HandleFunc("GET /api/replication/orchestrator", s.getOrchestratorStatus)
}

func (s *Server) healthCheck(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func (s *Server) createUser(w http.ResponseWriter, r *http.Request) {
	var req models.UserCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	user, err := s.userService.CreateUser(&req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(user)
}

func (s *Server) getUser(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	user, err := s.userService.GetUser(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func (s *Server) listUsers(w http.ResponseWriter, r *http.Request) {
	users, err := s.userService.ListUsers()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

func (s *Server) getReplicationStatus(w http.ResponseWriter, r *http.Request) {
	status, err := s.replicationService.GetStatus()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

func (s *Server) getOrchestratorStatus(w http.ResponseWriter, r *http.Request) {
	status, err := s.replicationService.CheckOrchestrator()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}
