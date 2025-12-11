# LabStream Docker Rebuild Script
# This script ensures Docker container is properly rebuilt with new code

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "LABSTREAM DOCKER REBUILD SCRIPT" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop all containers
Write-Host "[1/6] Stopping all containers..." -ForegroundColor Yellow
docker-compose down
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to stop containers" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Containers stopped" -ForegroundColor Green
Write-Host ""

# Step 2: Remove old images
Write-Host "[2/6] Removing old token-server image..." -ForegroundColor Yellow
docker rmi labstream-token-server -f 2>$null
Write-Host "✅ Old image removed" -ForegroundColor Green
Write-Host ""

# Step 3: Rebuild with no cache
Write-Host "[3/6] Rebuilding token-server (this may take 2-3 minutes)..." -ForegroundColor Yellow
docker-compose build --no-cache token-server
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build container" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Container rebuilt successfully" -ForegroundColor Green
Write-Host ""

# Step 4: Start containers
Write-Host "[4/6] Starting containers..." -ForegroundColor Yellow
docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to start containers" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Containers started" -ForegroundColor Green
Write-Host ""

# Step 5: Wait for services to be ready
Write-Host "[5/6] Waiting for services to start (10 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
Write-Host "✅ Services should be ready" -ForegroundColor Green
Write-Host ""

# Step 6: Show logs
Write-Host "[6/6] Checking token-server logs..." -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
docker logs labstream-token-server-1 --tail 30
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Verify
Write-Host "VERIFICATION:" -ForegroundColor Cyan
Write-Host "You should see in the logs above:" -ForegroundColor White
Write-Host "  ✅ 'Connected to PostgreSQL database'" -ForegroundColor Green
Write-Host "  ✅ 'LabStream Token Server running on port 3000'" -ForegroundColor Green
Write-Host ""
Write-Host "If you see these messages, rebuild was successful!" -ForegroundColor Green
Write-Host "If not, there's an error in the logs above." -ForegroundColor Red
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart Flutter app: flutter run -d windows" -ForegroundColor White
Write-Host "2. Login as instructor and join a room" -ForegroundColor White
Write-Host "3. Check database: SELECT * FROM sessions;" -ForegroundColor White
Write-Host "   You should see a NEW session created!" -ForegroundColor White
Write-Host ""
