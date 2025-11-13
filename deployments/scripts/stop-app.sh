#!/bin/bash

echo "🛑 Stopping Go Application..."

cd "$(dirname "$0")/.."
docker-compose -f app.docker-compose.yml down

echo "✅ Go application stopped successfully!"