#!/bin/bash

set -e

echo "🚀 Starting Full Stack (DB + App)..."

cd "$(dirname "$0")"

./start-db.sh
echo ""
./start-app.sh

echo ""
echo "🎉 Full stack started successfully!"
echo "   - Database cluster: running"
echo "   - Go application: http://localhost:8080"
echo ""
echo "🛑 To stop everything: ../../scripts/stop.sh"