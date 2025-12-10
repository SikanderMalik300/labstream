# LabStream Setup Guide

## Complete Setup Instructions for Windows

This guide will walk you through setting up and running LabStream on your Windows machine.

---

## Prerequisites

Before starting, ensure you have the following installed:

1. **Docker Desktop** - Download from https://www.docker.com/products/docker-desktop/
2. **Flutter SDK (3.0+)** - Download from https://docs.flutter.dev/get-started/install/windows
3. **Node.js (18+)** - Download from https://nodejs.org/
4. **Git** - Download from https://git-scm.com/download/win
5. **Visual Studio 2022** with "Desktop development with C++" workload

---

## Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd labstream
```

---

## Step 2: Start Docker Services

### 2.1 Make sure Docker Desktop is running

Open Docker Desktop application and wait for it to fully start.

### 2.2 Start all services using Docker Compose

Open a terminal in the project root directory and run:

```bash
docker-compose up -d
```

This will start:
- **PostgreSQL Database** (port 5432)
- **LiveKit Server** (ports 7880-7882)
- **Token Server** (port 3000)

### 2.3 Verify services are running

```bash
docker-compose ps
```

You should see three containers running:
- `labstream-postgres-1`
- `labstream-livekit-1`
- `labstream-token-server-1`

---

## Step 3: View and Access the Database

### Option 1: Using pgAdmin (Recommended for GUI)

1. **Download and install pgAdmin**: https://www.pgadmin.org/download/

2. **Connect to the database**:
   - Host: `localhost`
   - Port: `5432`
   - Database: `labstream`
   - Username: `labstream_user`
   - Password: `labstream_password`

3. **Browse tables**:
   - Expand Servers → PostgreSQL → Databases → labstream → Schemas → public → Tables
   - You'll see tables: `users`, `sessions`, `evaluations`, `blocks`, `chat_messages`, `hand_raises`

4. **View data**:
   - Right-click on any table → View/Edit Data → All Rows

### Option 2: Using Command Line

Access the database directly through Docker:

```bash
# Connect to PostgreSQL container
docker exec -it labstream-postgres-1 psql -U labstream_user -d labstream

# Inside psql, you can run SQL commands:
# List all tables
\dt

# View users
SELECT * FROM users;

# View evaluations
SELECT * FROM evaluations;

# View sessions
SELECT * FROM sessions;

# Exit
\q
```

### Option 3: Using VS Code Extension

1. Install the **PostgreSQL** extension by Chris Kolkman in VS Code
2. Create a new connection:
   - Host: `localhost`
   - Port: `5432`
   - Database: `labstream`
   - Username: `labstream_user`
   - Password: `labstream_password`
3. Browse and query tables directly from VS Code

---

## Step 4: Install Flutter Dependencies

```bash
flutter pub get
```

---

## Step 5: Run the Application

### Option 1: Run in Debug Mode

```bash
flutter run -d windows
```

### Option 2: Build Release Version

```bash
flutter build windows --release
```

The executable will be located at:
```
build/windows/runner/Release/labstream.exe
```

---

## Step 6: Using the Application

### For Students:

1. **Launch the app**
2. **Select "Student" role**
3. **Enter your information**:
   - Full Name: Your name
   - Student ID: Your unique student ID (e.g., "STD001")
   - Room Name: The room you want to join (e.g., "exam-room-1")
   - LiveKit Server URL: `ws://localhost:7880` (default)
4. **Click "Join Room"**

### For Instructors:

1. **Launch the app**
2. **Select "Instructor" role**
3. **Enter your information**:
   - Full Name: Your name
   - Instructor ID: Your unique instructor ID (e.g., "INST001")
   - Room Name: Create a new room name (e.g., "exam-room-1")
   - LiveKit Server URL: `ws://localhost:7880` (default)
4. **Click "Join Room"**

---

## Step 7: Monitoring and Debugging

### Check Token Server Logs

```bash
docker logs -f labstream-token-server-1
```

### Check LiveKit Server Logs

```bash
docker logs -f labstream-livekit-1
```

### Check PostgreSQL Logs

```bash
docker logs -f labstream-postgres-1
```

### View Live Database Changes

While the app is running, you can view database changes in real-time:

```bash
# In pgAdmin or psql, run queries to see current data:
SELECT * FROM users ORDER BY created_at DESC;
SELECT * FROM evaluations ORDER BY created_at DESC;
SELECT * FROM sessions ORDER BY started_at DESC;
```

---

## Step 8: Stopping the Services

When you're done testing:

```bash
# Stop all containers
docker-compose down

# Stop and remove all data (including database)
docker-compose down -v
```

---

## Troubleshooting

### Issue: "Port already in use"

**Solution**: Stop the conflicting service or change the port in `docker-compose.yml`

```bash
# Find what's using the port (PowerShell)
Get-Process -Id (Get-NetTCPConnection -LocalPort 5432).OwningProcess

# Or change the port in docker-compose.yml
```

### Issue: "Cannot connect to database"

**Solution**: Make sure PostgreSQL container is running

```bash
docker ps | grep postgres
docker-compose restart postgres
```

### Issue: "Flutter build fails"

**Solution**: Ensure Visual Studio with C++ tools is installed

```bash
flutter doctor -v
```

### Issue: "LiveKit connection failed"

**Solution**: Check if LiveKit container is running and accessible

```bash
docker ps | grep livekit
curl http://localhost:7880
```

### Issue: Database is empty

**Solution**: The database is initialized automatically. If tables are missing:

```bash
# Recreate database
docker-compose down -v
docker-compose up -d
```

---

## Database Schema Overview

### Users Table
- Stores student and instructor information
- Fields: `id`, `full_name`, `student_id`, `instructor_id`, `role`, `created_at`, `updated_at`

### Sessions Table
- Tracks active/past sessions
- Fields: `id`, `room_name`, `instructor_id`, `started_at`, `ended_at`, `participant_count`

### Evaluations Table
- Stores student evaluations
- Fields: `id`, `session_id`, `student_id`, `instructor_id`, `score`, `notes`, `created_at`, `updated_at`

### Blocks Table
- Tracks blocked students
- Fields: `id`, `session_id`, `student_id`, `instructor_id`, `duration`, `reason`, `created_at`, `expires_at`

### Chat Messages Table
- Stores chat history
- Fields: `id`, `session_id`, `sender_id`, `sender_name`, `content`, `message_type`, `timestamp`

### Hand Raises Table
- Tracks hand raises
- Fields: `id`, `session_id`, `student_id`, `raised_at`, `lowered_at`, `is_active`

---

## Real-time Data Updates

The application now supports **real-time data updates** without requiring hot reload:

### Evaluations Screen
- Automatically refreshes every 5 seconds to show new evaluations
- No manual refresh needed

### Participant List
- Updates automatically when participants join/leave
- Uses LiveKit real-time events

### Chat Messages
- Receives messages instantly via LiveKit data channels
- No polling required

---

## Performance Tips

1. **For testing with many users**: Increase Docker memory allocation in Docker Desktop settings (minimum 4GB recommended)

2. **Network performance**: Use wired connection for instructor machine when testing with 60+ participants

3. **Database performance**: The database has indexes on frequently queried fields for optimal performance

---

## Development Workflow

### Making Changes to the App

1. Edit Dart files in `lib/`
2. Hot reload: Press `r` in the terminal (debug mode)
3. Hot restart: Press `R` in the terminal (debug mode)
4. Test changes immediately

### Making Changes to Token Server

1. Edit `token-server/server.js`
2. Restart the container:
```bash
docker-compose restart token-server
```

### Making Changes to Database Schema

1. Edit `database/init.sql`
2. Recreate the database:
```bash
docker-compose down -v
docker-compose up -d
```

---

## Production Deployment Notes

Before deploying to production:

1. Change all default passwords in `.env` and `docker-compose.yml`
2. Use HTTPS for token server
3. Use WSS (secure WebSocket) for LiveKit
4. Set up proper PostgreSQL backups
5. Configure firewall rules
6. Use strong API keys and secrets
7. Enable SSL for database connections

---

## Support

For issues or questions:
1. Check the logs using the commands in Step 7
2. Verify all services are running with `docker-compose ps`
3. Review the main README.md for additional documentation

---

## Summary of Key Changes

### Recent Updates:
1. ✅ **Student ID** replaces "University ID" throughout the app
2. ✅ **Instructor ID** field added for instructor identification
3. ✅ **Real-time updates** - Evaluation screen auto-refreshes every 5 seconds
4. ✅ **Better error handling** - Improved error messages and crash prevention
5. ✅ **Database schema updated** - New fields `student_id` and `instructor_id`

---

## Quick Start Commands

```bash
# Complete setup from scratch
docker-compose up -d
flutter pub get
flutter run -d windows

# View database
docker exec -it labstream-postgres-1 psql -U labstream_user -d labstream

# Stop everything
docker-compose down
```

That's it! You're ready to use LabStream! 🎉
