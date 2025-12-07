#!/bin/bash

# LabStream Development Startup Script
# This script starts all required services for development

echo "🚀 Starting LabStream Development Environment..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Start Docker services
echo "📦 Starting Docker services (LiveKit, PostgreSQL, Token Server)..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

# Check LiveKit
if curl -s http://localhost:7880 > /dev/null; then
    echo "✅ LiveKit is running"
else
    echo "⚠️  LiveKit might not be ready yet"
fi

# Check Token Server
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Token Server is running"
else
    echo "⚠️  Token Server might not be ready yet"
fi

# Check PostgreSQL
if docker exec labstream-postgres-1 pg_isready -U labstream_user > /dev/null 2>&1; then
    echo "✅ PostgreSQL is running"
else
    echo "⚠️  PostgreSQL might not be ready yet"
fi

echo ""
echo "📱 Services are starting up!"
echo ""
echo "Next steps:"
echo "1. Run: flutter pub get"
echo "2. Run: flutter run -d windows"
echo ""
echo "To stop services: docker-compose down"
echo "To view logs: docker-compose logs -f"
echo ""
