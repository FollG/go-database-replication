package services

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/FollG/go-database-replication/internal/database/mysql"
)

type ReplicationService struct {
	db *mysql.DB
}

func NewReplicationService(db *mysql.DB) *ReplicationService {
	return &ReplicationService{db: db}
}

type ReplicationStatus struct {
	Master string `json:"master"`
	Slaves int    `json:"slaves_count"`
	Status string `json:"status"`
}

func (s *ReplicationService) GetStatus() (*ReplicationStatus, error) {
	// Проверяем доступность мастера
	err := s.db.Master.Ping()
	masterStatus := "healthy"
	if err != nil {
		masterStatus = "unhealthy"
	}

	// Проверяем доступность слейвов
	healthySlaves := 0
	for _, slave := range s.db.Slaves {
		if err := slave.Ping(); err == nil {
			healthySlaves++
		}
	}

	return &ReplicationStatus{
		Master: masterStatus,
		Slaves: healthySlaves,
		Status: fmt.Sprintf("Master: %s, Healthy slaves: %d/%d", masterStatus, healthySlaves, len(s.db.Slaves)),
	}, nil
}

func (s *ReplicationService) CheckOrchestrator() (map[string]interface{}, error) {
	// Запрос к Orchestrator API
	resp, err := http.Get("http://orchestrator:3000/api/clusters")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var clusters []map[string]interface{}
	if err := json.Unmarshal(body, &clusters); err != nil {
		return nil, err
	}

	if len(clusters) == 0 {
		return nil, fmt.Errorf("no clusters found")
	}

	return clusters[0], nil
}
