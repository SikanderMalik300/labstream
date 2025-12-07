# LabStream - Real-time Communication Platform

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-18+-339933?logo=node.js)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql)

LabStream is a Windows desktop application built with Flutter Desktop and LiveKit for real-time audio/video communication, designed specifically for online examinations and educational sessions.

## Features

### MVP Features ✨

- **Authentication**
  - Student login with full name and university ID
  - Instructor role selection
  - JWT token-based authentication

- **Real-time Communication**
  - Multi-user audio streaming
  - Multiple simultaneous screen sharing
  - Instructor controls for audio management
  - Grid view with expandable screens
  - Selective audio routing

- **Participant Management**
  - Scalable grid UI (60-150+ users)
  - Real-time participant status
  - Role-based controls

- **Chat System**
  - Text chat using LiveKit Data Channels
  - Hand-raise functionality
  - System notifications

- **Instructor Controls**
  - Mute individual or all students
  - Remove (kick) participants
  - Block students (10 min, 30 min, or permanent)
  - Persistent block state

- **Session Evaluation**
  - Score students (0-10 scale)
  - Add evaluation notes
  - Student score viewing

- **UI/UX**
  - Clean Material Design
  - Minimalist black-and-white theme
  - Small, readable text
  - Responsive desktop layout

---

## Architecture

```
┌──────────────────┐
│  Flutter Desktop │
│   (Windows App)  │
└────────┬─────────┘
         │
         ├──────────► LiveKit Server (WebRTC)
         │
         ├──────────► Token Server (Node.js + JWT)
         │
         └──────────► PostgreSQL Database
```

---

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0 or higher)
   - Download: https://docs.flutter.dev/get-started/install/windows

2. **Node.js** (18 or higher)
   - Download: https://nodejs.org/

3. **Docker Desktop** (for running LiveKit and PostgreSQL)
   - Download: https://www.docker.com/products/docker-desktop/

4. **Visual Studio** (for Windows C++ development)
   - Download: https://visualstudio.microsoft.com/downloads/
   - Required workload: "Desktop development with C++"

5. **Git**
   - Download: https://git-scm.com/download/win

---

## Project Structure

```
labstream/
├── lib/                        # Flutter application source code
│   ├── config/                # Configuration files
│   ├── models/                # Data models
│   ├── providers/             # State management
│   ├── screens/               # UI screens
│   ├── services/              # Business logic services
│   ├── widgets/               # Reusable UI widgets
│   └── main.dart              # Application entry point
├── token-server/              # Node.js authentication server
│   ├── server.js              # Server implementation
│   ├── package.json           # Node.js dependencies
│   └── Dockerfile             # Docker container config
├── database/                  # Database files
│   ├── init.sql               # Database initialization
│   └── DATABASE_SCHEMA.md     # Schema documentation
├── docker-compose.yml         # Docker services configuration
├── livekit-config.yaml        # LiveKit server configuration
├── pubspec.yaml               # Flutter dependencies
└── README.md                  # This file
```

---

## Quick Start Guide

### Option 1: Using Docker (Recommended)

#### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/labstream.git
cd labstream
```

#### Step 2: Configure Environment Variables

1. Generate LiveKit API credentials:
```bash
# Generate API key (or use any secure random string)
openssl rand -base64 32
```

2. Edit `livekit-config.yaml` and replace `your_api_key_here` with your generated key

3. Edit `docker-compose.yml` and update the following:
   - `LIVEKIT_API_KEY`
   - `LIVEKIT_API_SECRET`
   - Database passwords (if desired)

4. Copy and configure token server environment:
```bash
cd token-server
cp .env.example .env
# Edit .env and add your LiveKit credentials
```

#### Step 3: Start Services with Docker

```bash
# From the project root directory
docker-compose up -d
```

This will start:
- LiveKit Server (ports 7880-7882)
- PostgreSQL Database (port 5432)
- Token Server (port 3000)

#### Step 4: Install Flutter Dependencies

```bash
flutter pub get
```

#### Step 5: Run the Application

```bash
flutter run -d windows
```

---

### Option 2: Manual Setup

#### 1. Setup PostgreSQL

Install PostgreSQL 16+ and create the database:

```bash
# Login to PostgreSQL
psql -U postgres

# Create database and user
CREATE DATABASE labstream;
CREATE USER labstream_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE labstream TO labstream_user;

# Connect to database
\c labstream

# Run initialization script
\i database/init.sql
```

#### 2. Setup LiveKit Server

**Option A: Using LiveKit Cloud**
1. Sign up at https://cloud.livekit.io/
2. Create a project
3. Copy your API Key and Secret
4. Use the provided WebSocket URL

**Option B: Local Docker Installation**
```bash
docker run -d \
  --name livekit \
  -p 7880:7880 \
  -p 7881:7881 \
  -p 7882:7882/udp \
  -p 50000-50200:50000-50200/udp \
  -v $(pwd)/livekit-config.yaml:/etc/livekit.yaml \
  livekit/livekit-server:latest \
  --config /etc/livekit.yaml
```

#### 3. Setup Token Server

```bash
cd token-server

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start server
npm start
```

#### 4. Run Flutter Application

```bash
# From project root
flutter pub get
flutter run -d windows
```

---

## Building for Production

### Create Windows EXE

#### Method 1: Using MSIX (Recommended)

```bash
# Install dependencies
flutter pub get

# Build MSIX package
flutter build windows
flutter pub run msix:create
```

The MSIX installer will be created in `build/windows/runner/Release/`

#### Method 2: Manual Build

```bash
# Build release version
flutter build windows --release

# The executable will be in:
# build/windows/runner/Release/labstream.exe
```

To distribute, package the entire `Release` folder including:
- `labstream.exe`
- All `.dll` files
- `data/` folder

---

## Configuration

### Application Configuration

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String tokenServerUrl = 'http://your-server:3000';
  static const String liveKitUrl = 'ws://your-livekit-server:7880';
  // ... other settings
}
```

### LiveKit Configuration

Edit `livekit-config.yaml` for server settings:
- Port configuration
- Participant limits
- Timeout settings
- Turn server configuration

### Token Server Configuration

Edit `token-server/.env`:
```env
PORT=3000
LIVEKIT_API_KEY=your_api_key
LIVEKIT_API_SECRET=your_api_secret
LIVEKIT_URL=ws://localhost:7880
DB_HOST=localhost
DB_PORT=5432
DB_NAME=labstream
DB_USER=labstream_user
DB_PASSWORD=your_password
```

---

## Usage Guide

### For Students

1. **Login**
   - Enter your full name
   - Enter your university ID
   - Select "Student" role
   - Enter room name
   - Enter LiveKit server URL
   - Click "Join Room"

2. **During Session**
   - Your microphone is automatically enabled
   - Click screen share button to share your screen
   - Use chat to communicate
   - Click "Raise Hand" when you need assistance
   - View your evaluations by clicking the evaluation icon

### For Instructors

1. **Login**
   - Enter your full name
   - Select "Instructor" role
   - Enter room name (create a new one)
   - Enter LiveKit server URL
   - Click "Join Room"

2. **During Session**
   - View all participants in grid layout
   - Click any student's screen tile to enlarge it
   - Use controls for each student:
     - **Mute**: Mute individual student
     - **Kick**: Remove student from session
     - **Block**: Block student (10 min, 30 min, or permanent)
     - **Score**: Evaluate student performance
   - Click "Mute All" to mute all students at once
   - Share your screen to broadcast to all students

---

## Database Schema

For detailed database schema information, see [DATABASE_SCHEMA.md](database/DATABASE_SCHEMA.md)

### Key Tables:
- `users` - User accounts (students and instructors)
- `sessions` - Exam/class sessions
- `blocks` - Student blocking records
- `evaluations` - Student performance evaluations
- `chat_messages` - Chat history
- `hand_raises` - Hand raise tracking

---

## API Endpoints

### Token Server API

**Base URL:** `http://localhost:3000`

#### POST `/api/auth/login`
Login and create user session.

**Request:**
```json
{
  "fullName": "John Doe",
  "universityId": "STD001",
  "role": "student"
}
```

**Response:**
```json
{
  "userId": "uuid",
  "token": "base64-token",
  "user": { ... }
}
```

#### POST `/api/auth/token`
Get LiveKit room token.

**Request:**
```json
{
  "userId": "uuid",
  "roomName": "exam-room-1",
  "role": "student"
}
```

**Response:**
```json
{
  "token": "jwt-token"
}
```

#### POST `/api/blocks`
Create a block record.

#### GET `/api/blocks/:studentId`
Get active blocks for a student.

#### POST `/api/evaluations`
Save student evaluation.

#### GET `/api/evaluations/:studentId`
Get all evaluations for a student.

---

## Troubleshooting

### Common Issues

#### 1. Flutter Build Fails

**Error:** "Visual Studio not found"

**Solution:** Install Visual Studio with C++ desktop development workload

#### 2. LiveKit Connection Failed

**Error:** "Failed to connect to LiveKit"

**Solutions:**
- Check if LiveKit server is running: `docker ps`
- Verify LiveKit URL in app configuration
- Check firewall settings
- Ensure ports 7880-7882 are not blocked

#### 3. Token Server Connection Failed

**Error:** "Login failed"

**Solutions:**
- Check if token server is running: `curl http://localhost:3000/health`
- Verify token server URL in app configuration
- Check token server logs: `docker logs labstream-token-server-1`

#### 4. Database Connection Issues

**Solutions:**
- Check if PostgreSQL is running: `docker ps | grep postgres`
- Verify database credentials in token server `.env`
- Check database logs: `docker logs labstream-postgres-1`

#### 5. Audio/Video Not Working

**Solutions:**
- Grant microphone/camera permissions to the app
- Check Windows privacy settings
- Restart the application
- Verify LiveKit server is properly configured

---

## Performance Optimization

### For 60-150 Participants

1. **Network Requirements**
   - Minimum: 10 Mbps upload/download per user
   - Recommended: 50 Mbps+ for instructor

2. **Hardware Requirements**
   - CPU: Intel i5 (8th gen) or equivalent
   - RAM: 8 GB minimum, 16 GB recommended
   - GPU: Integrated graphics sufficient

3. **Server Requirements**
   - CPU: 4+ cores
   - RAM: 8 GB+ for LiveKit server
   - Network: 1 Gbps connection

---

## Security Considerations

1. **JWT Tokens**
   - Tokens expire after session duration
   - Use secure secret keys in production

2. **Database**
   - Use strong passwords
   - Enable SSL connections in production
   - Regular backups

3. **Network**
   - Use HTTPS for token server in production
   - Use WSS (secure WebSocket) for LiveKit
   - Configure firewall rules

4. **Application**
   - Validate all user inputs
   - Sanitize chat messages
   - Implement rate limiting

---

## Development

### Running Tests

```bash
flutter test
```

### Code Formatting

```bash
flutter format lib/
```

### Linting

```bash
flutter analyze
```

---

## Deployment

### Production Checklist

- [ ] Update LiveKit server to production URL
- [ ] Configure HTTPS for token server
- [ ] Use production database with backups
- [ ] Enable SSL for PostgreSQL
- [ ] Configure proper CORS settings
- [ ] Set strong passwords and secrets
- [ ] Configure monitoring and logging
- [ ] Test with expected user load
- [ ] Create installation package
- [ ] Prepare user documentation

---

## License

This project is licensed under the MIT License.

---

## Support

For issues and questions:
- Create an issue on GitHub
- Email: support@labstream.example.com

---

## Contributors

- Your Name - Initial work

---

## Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [LiveKit](https://livekit.io/) - Real-time communication
- [PostgreSQL](https://www.postgresql.org/) - Database
- [Node.js](https://nodejs.org/) - Token server

---

## Changelog

### Version 1.0.0 (Initial Release)
- Complete MVP implementation
- All core features functional
- Windows desktop support
- Docker deployment support
- Comprehensive documentation
