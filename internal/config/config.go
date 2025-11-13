package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

type Config struct {
	HTTP     HTTPConfig     `yaml:"http"`
	Database DatabaseConfig `yaml:"database"`
}

type HTTPConfig struct {
	Port string `yaml:"port"`
}

type DatabaseConfig struct {
	Master   string   `yaml:"master"`
	Slaves   []string `yaml:"slaves"`
	Username string   `yaml:"username"`
	Password string   `yaml:"password"`
	Database string   `yaml:"database"`
	MaxConns int      `yaml:"max_conns"`
	MaxIdle  int      `yaml:"max_idle"`
}

func Load() (*Config, error) {
	env := os.Getenv("APP_ENV")
	if env == "" {
		env = "dev"
	}

	configPath := fmt.Sprintf("configs/config.%s.yaml", env)
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %v", err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config: %v", err)
	}

	// Override with environment variables if set
	if port := os.Getenv("HTTP_PORT"); port != "" {
		config.HTTP.Port = port
	}

	return &config, nil
}
