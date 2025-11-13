#!/bin/bash

echo "🛑 Stopping MySQL Cluster..."

cd "$(dirname "$0")/.."
docker-compose -f db.docker-compose.yml down

echo "✅ MySQL cluster stopped successfully!"