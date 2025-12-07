# LabStream - Quick Start Guide

Get LabStream up and running in 5 minutes!

## 🚀 Fast Setup (Using Docker)

### Prerequisites
- Docker Desktop installed
- Flutter SDK installed
- 5 minutes of your time

### Step-by-Step

#### 1️⃣ Generate LiveKit Credentials

```bash
# Generate a secure API key
openssl rand -base64 32
# Output example: "your_generated_key_here"
```

Copy this key for the next steps.

#### 2️⃣ Configure LiveKit

Edit `livekit-config.yaml`, find this line:
```yaml
keys:
  API_KEY: your_api_key_here
```

Replace `your_api_key_here` with your generated key.

#### 3️⃣ Configure Docker

Edit `docker-compose.yml`, replace these values:
```yaml
LIVEKIT_API_KEY=your_generated_key_here
LIVEKIT_API_SECRET=your_generated_key_here
```

#### 4️⃣ Start All Services

```bash
docker-compose up -d
```

Wait 30 seconds for services to start.

#### 5️⃣ Verify Services

```bash
# Check all containers are running
docker ps

# Should show 3 containers:
# - livekit
# - postgres
# - token-server
```

#### 6️⃣ Run the Flutter App

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run -d windows
```

### 🎉 You're Ready!

The login screen should appear. Try logging in:

**As Instructor:**
- Full Name: `Dr. Smith`
- Role: `Instructor`
- Room Name: `test-room`
- LiveKit URL: `ws://localhost:7880`

**As Student (in another instance):**
- Full Name: `John Doe`
- University ID: `STD001`
- Role: `Student`
- Room Name: `test-room`
- LiveKit URL: `ws://localhost:7880`

---

## 🐛 Troubleshooting

### Services won't start?

```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### Can't connect to LiveKit?

Check if port 7880 is accessible:
```bash
curl http://localhost:7880
```

### Token server not responding?

```bash
# Check health
curl http://localhost:3000/health

# Should return: {"status":"healthy",...}
```

---

## 📝 Next Steps

1. **Read the Full Documentation**: [README.md](README.md)
2. **Build for Windows**: [BUILD_WINDOWS.md](BUILD_WINDOWS.md)
3. **Database Schema**: [database/DATABASE_SCHEMA.md](database/DATABASE_SCHEMA.md)

---

## 🔑 Default Configuration

- **LiveKit Server**: `ws://localhost:7880`
- **Token Server**: `http://localhost:3000`
- **PostgreSQL**: `localhost:5432`
  - Database: `labstream`
  - User: `labstream_user`
  - Password: `labstream_password`

---

## 💡 Tips

- Use the same room name for both instructor and students
- Instructor should join first to create the room
- Maximum 150 participants per room
- Audio is auto-enabled for students
- Instructors can control all participant audio

---

## ⚠️ Common Mistakes

1. ❌ Different room names for instructor and students
2. ❌ Forgetting to start Docker services
3. ❌ Using wrong LiveKit URL (check http vs ws)
4. ❌ Firewall blocking ports 7880-7882

---

## 🆘 Need Help?

Create an issue on GitHub with:
- Error message
- Steps to reproduce
- Docker logs: `docker-compose logs`
- Flutter doctor output: `flutter doctor -v`
