@echo off
REM LabStream Development Startup Script for Windows
REM This script starts all required services for development

echo.
echo 🚀 Starting LabStream Development Environment...
echo.

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not running. Please start Docker Desktop first.
    exit /b 1
)

REM Start Docker services
echo 📦 Starting Docker services (LiveKit, PostgreSQL, Token Server)...
docker-compose up -d

REM Wait for services to be ready
echo ⏳ Waiting for services to start...
timeout /t 10 /nobreak >nul

REM Check service health
echo 🔍 Checking service health...

REM Check Token Server
curl -s http://localhost:3000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Token Server is running
) else (
    echo ⚠️  Token Server might not be ready yet
)

echo.
echo 📱 Services are starting up!
echo.
echo Next steps:
echo 1. Run: flutter pub get
echo 2. Run: flutter run -d windows
echo.
echo To stop services: docker-compose down
echo To view logs: docker-compose logs -f
echo.

pause
