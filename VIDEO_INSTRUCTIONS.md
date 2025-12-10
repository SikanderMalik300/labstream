# Video Setup Instructions

If you prefer video instructions, here's a step-by-step guide to record a setup video:

## Video Script / Steps to Record

### Part 1: Prerequisites (2-3 minutes)
1. Show Docker Desktop installation and startup
2. Show Flutter SDK installation verification: `flutter doctor`
3. Show Node.js installation verification: `node --version`
4. Show Visual Studio with C++ workload installed

### Part 2: Starting the Services (3-4 minutes)
1. Open terminal in project directory
2. Run `docker-compose up -d`
3. Run `docker-compose ps` to show running containers
4. Explain what each container does:
   - PostgreSQL: Database
   - LiveKit: Real-time communication
   - Token Server: Authentication

### Part 3: Viewing the Database (4-5 minutes)

#### Using pgAdmin:
1. Open pgAdmin
2. Create new server connection:
   - Name: LabStream
   - Host: localhost
   - Port: 5432
   - Database: labstream
   - Username: labstream_user
   - Password: labstream_password
3. Navigate to Tables
4. Show the tables:
   - users
   - sessions
   - evaluations
   - blocks
   - chat_messages
   - hand_raises
5. Right-click on `users` → View/Edit Data → All Rows
6. Show empty table (will populate when app runs)

#### Using Command Line:
1. Open terminal
2. Run: `docker exec -it labstream-postgres-1 psql -U labstream_user -d labstream`
3. Run: `\dt` to list tables
4. Run: `SELECT * FROM users;` (will be empty initially)
5. Run: `\q` to exit

### Part 4: Running the Application (3-4 minutes)
1. Open terminal in project directory
2. Run `flutter pub get`
3. Run `flutter run -d windows`
4. Wait for app to build and launch
5. Show the login screen

### Part 5: Testing as Student (2-3 minutes)
1. Select "Student" role
2. Enter:
   - Full Name: "John Doe"
   - Student ID: "STD001"
   - Room Name: "test-room-1"
   - LiveKit URL: ws://localhost:7880
3. Click "Join Room"
4. Show the room interface

### Part 6: Viewing Database Changes (2-3 minutes)
1. Switch to pgAdmin
2. Refresh the `users` table
3. Show the newly created student user with:
   - full_name: "John Doe"
   - student_id: "STD001"
   - role: "student"
4. Show the `sessions` table to see the active session

### Part 7: Testing as Instructor (3-4 minutes)
1. Run the app again (second instance): `flutter run -d windows`
2. Select "Instructor" role
3. Enter:
   - Full Name: "Dr. Smith"
   - Instructor ID: "INST001"
   - Room Name: "test-room-1" (same room)
   - LiveKit URL: ws://localhost:7880
4. Click "Join Room"
5. Show the instructor interface with student visible

### Part 8: Testing Evaluations (3-4 minutes)
1. As instructor, click on student tile
2. Click "Evaluate" button
3. Enter:
   - Score: 8.5
   - Notes: "Great work on the exam"
4. Click "Save"
5. Switch to database view
6. Refresh `evaluations` table
7. Show the new evaluation record:
   - student_id: (student UUID)
   - instructor_id: (instructor UUID)
   - score: 8.5
   - notes: "Great work on the exam"
8. As student, click evaluations icon
9. Show the evaluation appearing in the student's view
10. Explain auto-refresh (updates every 5 seconds)

### Part 9: Real-time Updates Demo (2-3 minutes)
1. Keep both instances open
2. As instructor, create another evaluation with different score
3. Wait 5 seconds
4. Show student's evaluation screen automatically updating
5. Explain: "No refresh button needed - it updates automatically!"

### Part 10: Viewing Logs (2 minutes)
1. Open terminal
2. Show token server logs: `docker logs -f labstream-token-server-1`
3. Show LiveKit logs: `docker logs -f labstream-livekit-1`
4. Show PostgreSQL logs: `docker logs -f labstream-postgres-1`
5. Explain what each log shows

### Part 11: Stopping Services (1 minute)
1. Close both app instances
2. Run: `docker-compose down`
3. Show containers stopping
4. Explain: Use `docker-compose down -v` to also delete database data

---

## Key Points to Emphasize in Video

1. ✅ **Student ID vs Instructor ID**: Show both fields clearly
2. ✅ **Real-time updates**: Demonstrate the auto-refresh feature
3. ✅ **Database persistence**: Show how data persists between app restarts
4. ✅ **Multiple instances**: Run student and instructor simultaneously
5. ✅ **Easy setup**: Emphasize how easy it is with Docker

---

## Recording Tips

### Software Recommendations:
- **OBS Studio** (free): https://obsproject.com/
- **ShareX** (free, Windows): https://getsharex.com/
- **Camtasia** (paid): https://www.techsmith.com/video-editor.html

### Recording Settings:
- Resolution: 1920x1080 (Full HD)
- Frame rate: 30 fps
- Format: MP4
- Audio: Clear voice narration

### Editing:
- Add text overlays for important commands
- Highlight mouse cursor for visibility
- Add chapters/timestamps in description
- Keep video under 25 minutes total

---

## Video Chapters/Timestamps

Use these in your video description:

```
0:00 - Introduction
0:30 - Prerequisites Overview
3:00 - Starting Docker Services
6:00 - Accessing the Database (pgAdmin)
10:00 - Accessing the Database (Command Line)
12:00 - Running the Flutter App
15:00 - Testing as Student
17:00 - Testing as Instructor
20:00 - Creating and Viewing Evaluations
23:00 - Real-time Updates Demo
25:00 - Viewing Logs
26:00 - Stopping Services
27:00 - Conclusion & Next Steps
```

---

## Example Video Description

```
LabStream Setup Guide - Complete Walkthrough

Learn how to set up and run LabStream, a real-time communication platform
for online examinations and educational sessions.

📦 What You'll Learn:
✅ Install and configure Docker services
✅ View and query the PostgreSQL database
✅ Run the Flutter Windows application
✅ Test with student and instructor roles
✅ Create evaluations and see real-time updates
✅ Monitor logs and troubleshoot issues

🔗 Links:
- Repository: [Your GitHub URL]
- Setup Guide: SETUP_GUIDE.md
- Documentation: README.md

⏱️ Timestamps:
[Insert timestamps from above]

💬 Questions? Leave a comment below!

#Flutter #LiveKit #PostgreSQL #Docker #RealTime
```

---

## Alternative: Quick Setup Video (5 minutes)

If you prefer a shorter video, focus on:

1. **Quick Prerequisites** (30 seconds)
2. **Start Docker** (1 minute)
   - `docker-compose up -d`
3. **View Database in pgAdmin** (1 minute)
   - Quick connection demo
4. **Run App** (1 minute)
   - `flutter run -d windows`
5. **Login and Test** (1.5 minutes)
   - One student, one instructor
   - Quick evaluation
6. **Show Real-time Update** (30 seconds)

This covers the essentials for users who want to get started quickly!
