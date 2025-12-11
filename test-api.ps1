# Test API Endpoints
# This script tests if the new PostgreSQL endpoints are working

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "API ENDPOINT TEST SCRIPT" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:3001"

# Test 1: Health Check
Write-Host "[Test 1] Health check..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✅ Server is healthy" -ForegroundColor Green
    Write-Host "   Status: $($data.status)" -ForegroundColor Gray
} catch {
    Write-Host "❌ FAILED: Server is not responding!" -ForegroundColor Red
    Write-Host "   Make sure Docker containers are running: docker ps" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Test 2: Login endpoint
Write-Host "[Test 2] Testing login endpoint..." -ForegroundColor Yellow
try {
    $body = @{
        fullName = "Test User"
        studentId = "TEST001"
        role = "student"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/auth/login" -Method POST `
        -ContentType "application/json" -Body $body
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✅ Login endpoint working" -ForegroundColor Green
    Write-Host "   User ID: $($data.userId)" -ForegroundColor Gray
    $userId = $data.userId
} catch {
    Write-Host "❌ FAILED: Login endpoint error" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 3: Token endpoint (creates session for instructor)
Write-Host "[Test 3] Testing token endpoint..." -ForegroundColor Yellow
try {
    # First login as instructor
    $body = @{
        fullName = "Test Instructor"
        instructorId = "INST001"
        role = "instructor"
    } | ConvertTo-Json

    $loginResponse = Invoke-WebRequest -Uri "$baseUrl/api/auth/login" -Method POST `
        -ContentType "application/json" -Body $body
    $loginData = $loginResponse.Content | ConvertFrom-Json

    # Then get token (should create session)
    $body = @{
        userId = $loginData.userId
        roomName = "test-room-api"
        role = "instructor"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/auth/token" -Method POST `
        -ContentType "application/json" -Body $body
    $data = $response.Content | ConvertFrom-Json
    Write-Host "✅ Token endpoint working" -ForegroundColor Green
    Write-Host "   Token generated successfully" -ForegroundColor Gray
} catch {
    Write-Host "❌ FAILED: Token endpoint error" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 4: Chat message endpoint
Write-Host "[Test 4] Testing chat message endpoint..." -ForegroundColor Yellow
try {
    $body = @{
        sessionId = "test-session-123"
        senderId = $userId
        senderName = "Test User"
        content = "Hello from API test!"
        messageType = "text"
        isFromInstructor = $false
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/chat/messages" -Method POST `
        -ContentType "application/json" -Body $body
    Write-Host "✅ Chat message endpoint working" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: Chat message endpoint not found or error" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    Write-Host "   This means Docker is running OLD code!" -ForegroundColor Red
    Write-Host "   Run: .\fix-docker.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Test 5: Hand raise endpoint
Write-Host "[Test 5] Testing hand raise endpoint..." -ForegroundColor Yellow
try {
    $body = @{
        sessionId = "test-session-123"
        studentId = $userId
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$baseUrl/api/hand-raises" -Method POST `
        -ContentType "application/json" -Body $body
    Write-Host "✅ Hand raise endpoint working" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: Hand raise endpoint not found or error" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    Write-Host "   This means Docker is running OLD code!" -ForegroundColor Red
    Write-Host "   Run: .\fix-docker.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "ALL TESTS PASSED! ✅" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The server is running the NEW code with all endpoints working." -ForegroundColor Green
Write-Host "You can now use the Flutter app and data will save to PostgreSQL." -ForegroundColor Green
Write-Host ""
