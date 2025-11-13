package services

import (
	"database/sql"
	"errors"
	"log"

	"github.com/FollG/go-database-replication/internal/database/mysql"
	"github.com/FollG/go-database-replication/internal/models"
)

type UserService struct {
	db *mysql.DB
}

func NewUserService(db *mysql.DB) *UserService {
	return &UserService{db: db}
}

func (s *UserService) CreateUser(user *models.UserCreateRequest) (*models.UserResponse, error) {
	query := `INSERT INTO users (name, email) VALUES (?, ?)`

	result, err := s.db.Write(query, user.Name, user.Email)
	if err != nil {
		return nil, err
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}

	// Читаем созданного пользователя для ответа
	var createdUser models.UserResponse
	row, _ := s.db.ReadRow("SELECT id, name, email, created_at FROM users WHERE id = ?", id)
	err = row.Scan(&createdUser.ID, &createdUser.Name, &createdUser.Email, &createdUser.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &createdUser, nil
}

func (s *UserService) GetUser(id int) (*models.UserResponse, error) {
	var user models.UserResponse

	row, err := s.db.ReadRow("SELECT id, name, email, created_at FROM users WHERE id = ?", id)
	if err != nil {
		return nil, err
	}

	err = row.Scan(&user.ID, &user.Name, &user.Email, &user.CreatedAt)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New("user not found")
		}
		return nil, err
	}

	return &user, nil
}

func (s *UserService) ListUsers() ([]models.UserResponse, error) {
	rows, err := s.db.Read("SELECT id, name, email, created_at FROM users ORDER BY id DESC")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []models.UserResponse
	for rows.Next() {
		var user models.UserResponse
		if err := rows.Scan(&user.ID, &user.Name, &user.Email, &user.CreatedAt); err != nil {
			log.Printf("Error scanning user: %v", err)
			continue
		}
		users = append(users, user)
	}

	return users, nil
}
