const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const dotenv = require('dotenv');
const { v4: uuidv4 } = require('uuid');
const { AccessToken } = require('livekit-server-sdk');

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

// In-memory storage (replace with PostgreSQL in production)
const users = new Map();
const sessions = new Map();
const blocks = new Map();
const evaluations = new Map();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Login endpoint
app.post('/api/auth/login', (req, res) => {
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

    // Store user
    const user = {
      id: userId,
      fullName,
      studentId: studentId || null,
      instructorId: instructorId || null,
      role,
      createdAt: new Date().toISOString()
    };

    users.set(userId, user);

    // Generate simple session token (in production, use proper JWT)
    const sessionToken = Buffer.from(JSON.stringify({ userId, role }))
      .toString('base64');

    res.json({
      userId,
      token: sessionToken,
      user
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

    // Get user data
    const user = users.get(userId);
    if (!user) {
      console.log('❌ User not found:', userId);
      return res.status(404).json({
        error: 'User not found'
      });
    }

    console.log('✅ User found:', user.fullName);
    console.log('🔑 Using API Key:', process.env.LIVEKIT_API_KEY);
    console.log('🔑 Using API Secret:', process.env.LIVEKIT_API_SECRET ? 'SET' : 'NOT SET');

    // Create LiveKit access token
    const at = new AccessToken(
      process.env.LIVEKIT_API_KEY,
      process.env.LIVEKIT_API_SECRET,
      {
        identity: userId,
        name: user.fullName,
        metadata: JSON.stringify({
          fullName: user.fullName,
          studentId: user.studentId,
          instructorId: user.instructorId,
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
app.post('/api/blocks', (req, res) => {
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

    // Store block (use student ID as key for easy lookup)
    if (!blocks.has(studentId)) {
      blocks.set(studentId, []);
    }
    blocks.get(studentId).push(block);

    res.status(201).json(block);
  } catch (error) {
    console.error('Block creation error:', error);
    res.status(500).json({ error: 'Failed to create block' });
  }
});

// Get blocks for a student
app.get('/api/blocks/:studentId', (req, res) => {
  try {
    const { studentId } = req.params;
    const studentBlocks = blocks.get(studentId) || [];

    // Filter active blocks
    const now = new Date();
    const activeBlocks = studentBlocks.filter(block => {
      if (!block.expiresAt) return true; // Permanent block
      return new Date(block.expiresAt) > now;
    });

    res.json(activeBlocks);
  } catch (error) {
    console.error('Error fetching blocks:', error);
    res.status(500).json({ error: 'Failed to fetch blocks' });
  }
});

// Save evaluation endpoint
app.post('/api/evaluations', (req, res) => {
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
      createdAt: now,
      updatedAt: now
    };

    // Store evaluation
    const key = `${studentId}_${sessionId}`;
    evaluations.set(key, evaluation);

    res.status(201).json(evaluation);
  } catch (error) {
    console.error('Evaluation creation error:', error);
    res.status(500).json({ error: 'Failed to create evaluation' });
  }
});

// Get evaluations for a student
app.get('/api/evaluations/:studentId', (req, res) => {
  try {
    const { studentId } = req.params;
    const studentEvaluations = [];

    // Find all evaluations for this student
    for (const [key, evaluation] of evaluations) {
      if (evaluation.studentId === studentId) {
        studentEvaluations.push(evaluation);
      }
    }

    // Sort by creation date (newest first)
    studentEvaluations.sort((a, b) =>
      new Date(b.createdAt) - new Date(a.createdAt)
    );

    res.json(studentEvaluations);
  } catch (error) {
    console.error('Error fetching evaluations:', error);
    res.status(500).json({ error: 'Failed to fetch evaluations' });
  }
});

// Create session endpoint
app.post('/api/sessions', (req, res) => {
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
      endedAt: null,
      participantCount: 0
    };

    sessions.set(sessionId, session);

    res.status(201).json(session);
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
