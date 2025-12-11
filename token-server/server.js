const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const dotenv = require('dotenv');
const { v4: uuidv4 } = require('uuid');
const { AccessToken } = require('livekit-server-sdk');
const { userQueries, sessionQueries, evaluationQueries, blockQueries } = require('./db');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  if (req.method === 'POST') {
    console.log('Body:', JSON.stringify(req.body));
  }
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Login endpoint
app.post('/api/auth/login', async (req, res) => {
  try {
    const { fullName, studentId, instructorId, role } = req.body;

    if (!fullName || !role) {
      return res.status(400).json({
        error: 'Missing required fields: fullName and role are required'
      });
    }

    if (role !== 'student' && role !== 'instructor') {
      return res.status(400).json({
        error: 'Invalid role. Must be either "student" or "instructor"'
      });
    }

    if (role === 'student' && !studentId) {
      return res.status(400).json({
        error: 'Student ID is required for students'
      });
    }

    if (role === 'instructor' && !instructorId) {
      return res.status(400).json({
        error: 'Instructor ID is required for instructors'
      });
    }

    // Generate user ID
    const userId = uuidv4();

    // Store user in PostgreSQL
    const user = {
      id: userId,
      fullName,
      studentId: studentId || null,
      instructorId: instructorId || null,
      role,
      createdAt: new Date().toISOString()
    };

    const savedUser = await userQueries.create(user);
    console.log('✅ User saved to PostgreSQL:', savedUser);

    // Generate simple session token (in production, use proper JWT)
    const sessionToken = Buffer.from(JSON.stringify({ userId, role }))
      .toString('base64');

    res.json({
      userId,
      token: sessionToken,
      user: savedUser
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get LiveKit room token endpoint
app.post('/api/auth/token', async (req, res) => {
  try {
    const { userId, roomName, role } = req.body;

    console.log('🎫 Token request received:', { userId, roomName, role });

    if (!userId || !roomName || !role) {
      console.log('❌ Missing required fields');
      return res.status(400).json({
        error: 'Missing required fields: userId, roomName, and role are required'
      });
    }

    // Get user data from PostgreSQL
    const user = await userQueries.findById(userId);
    if (!user) {
      console.log('❌ User not found:', userId);
      return res.status(404).json({
        error: 'User not found'
      });
    }

    console.log('✅ User found:', user.full_name);
    console.log('🔑 Using API Key:', process.env.LIVEKIT_API_KEY);
    console.log('🔑 Using API Secret:', process.env.LIVEKIT_API_SECRET ? 'SET' : 'NOT SET');

    // Create or get session for this room (instructors only)
    if (role === 'instructor') {
      let session = await sessionQueries.findByRoomName(roomName);
      if (!session) {
        const newSession = {
          id: uuidv4(),
          roomName,
          instructorId: userId,
          startedAt: new Date().toISOString(),
          participantCount: 0
        };
        session = await sessionQueries.create(newSession);
        console.log('✅ Session created in PostgreSQL:', session);
      }
    }

    // Create LiveKit access token
    const at = new AccessToken(
      process.env.LIVEKIT_API_KEY,
      process.env.LIVEKIT_API_SECRET,
      {
        identity: userId,
        name: user.full_name,
        metadata: JSON.stringify({
          fullName: user.full_name,
          studentId: user.student_id,
          instructorId: user.instructor_id,
          role: user.role
        })
      }
    );

    // Set permissions based on role
    const canPublish = role === 'student' || role === 'instructor';
    const canSubscribe = true;
    const canPublishData = true;

    at.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish,
      canSubscribe,
      canPublishData,
      canUpdateOwnMetadata: true
    });

    const token = await at.toJwt();

    console.log('✅ Token generated successfully');
    console.log('Token (first 50 chars):', token.substring(0, 50) + '...');

    res.json({ token });
  } catch (error) {
    console.error('❌ Token generation error:', error);
    res.status(500).json({ error: 'Failed to generate token' });
  }
});

// Block student endpoint
app.post('/api/blocks', async (req, res) => {
  try {
    const { sessionId, studentId, instructorId, duration, reason } = req.body;

    if (!sessionId || !studentId || !instructorId || !duration) {
      return res.status(400).json({
        error: 'Missing required fields'
      });
    }

    const blockId = uuidv4();
    const createdAt = new Date();
    let expiresAt = null;

    if (duration === 'minutes10') {
      expiresAt = new Date(createdAt.getTime() + 10 * 60 * 1000);
    } else if (duration === 'minutes30') {
      expiresAt = new Date(createdAt.getTime() + 30 * 60 * 1000);
    }
    // If duration is 'permanent', expiresAt stays null

    const block = {
      id: blockId,
      sessionId,
      studentId,
      instructorId,
      duration,
      reason: reason || null,
      createdAt: createdAt.toISOString(),
      expiresAt: expiresAt ? expiresAt.toISOString() : null
    };

    // Save block to PostgreSQL
    const savedBlock = await blockQueries.create(block);
    console.log('✅ Block saved to PostgreSQL:', savedBlock);

    res.status(201).json(savedBlock);
  } catch (error) {
    console.error('Block creation error:', error);
    res.status(500).json({ error: 'Failed to create block' });
  }
});

// Get blocks for a student
app.get('/api/blocks/:studentId', async (req, res) => {
  try {
    const { studentId } = req.params;
    const block = await blockQueries.isBlocked(studentId);

    res.json(block ? [block] : []);
  } catch (error) {
    console.error('Error fetching blocks:', error);
    res.status(500).json({ error: 'Failed to fetch blocks' });
  }
});

// Save evaluation endpoint
app.post('/api/evaluations', async (req, res) => {
  try {
    const { id, sessionId, studentId, instructorId, score, notes } = req.body;

    if (!sessionId || !studentId || !instructorId || score === undefined) {
      return res.status(400).json({
        error: 'Missing required fields'
      });
    }

    if (score < 0 || score > 10) {
      return res.status(400).json({
        error: 'Score must be between 0 and 10'
      });
    }

    const evaluationId = id || uuidv4();
    const now = new Date().toISOString();

    const evaluation = {
      id: evaluationId,
      sessionId,
      studentId,
      instructorId,
      score,
      notes: notes || null,
      createdAt: now
    };

    // Save evaluation to PostgreSQL
    const savedEvaluation = await evaluationQueries.create(evaluation);
    console.log('✅ Evaluation saved to PostgreSQL:', savedEvaluation);

    res.status(201).json(savedEvaluation);
  } catch (error) {
    console.error('Evaluation creation error:', error);
    res.status(500).json({ error: 'Failed to create evaluation' });
  }
});

// Get evaluations for a student
app.get('/api/evaluations/:studentId', async (req, res) => {
  try {
    const { studentId } = req.params;
    const studentEvaluations = await evaluationQueries.findByStudent(studentId);

    res.json(studentEvaluations);
  } catch (error) {
    console.error('Error fetching evaluations:', error);
    res.status(500).json({ error: 'Failed to fetch evaluations' });
  }
});

// Create session endpoint
app.post('/api/sessions', async (req, res) => {
  try {
    const { roomName, instructorId } = req.body;

    if (!roomName || !instructorId) {
      return res.status(400).json({
        error: 'Missing required fields: roomName and instructorId'
      });
    }

    const sessionId = uuidv4();
    const session = {
      id: sessionId,
      roomName,
      instructorId,
      startedAt: new Date().toISOString(),
      participantCount: 0
    };

    // Save session to PostgreSQL
    const savedSession = await sessionQueries.create(session);
    console.log('✅ Session saved to PostgreSQL:', savedSession);

    res.status(201).json(savedSession);
  } catch (error) {
    console.error('Session creation error:', error);
    res.status(500).json({ error: 'Failed to create session' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`LabStream Token Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`LiveKit URL: ${process.env.LIVEKIT_URL}`);
});
