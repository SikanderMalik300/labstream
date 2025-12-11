const { Pool } = require('pg');

// Create PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'labstream',
  user: process.env.DB_USER || 'labstream_user',
  password: process.env.DB_PASSWORD || 'labstream_pass',
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test connection on startup
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected database error:', err);
});

// Query helper function
async function query(text, params) {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('📊 Query executed', { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    console.error('❌ Database query error:', error);
    throw error;
  }
}

// Transaction helper
async function transaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

// User operations
const userQueries = {
  create: async (user) => {
    const result = await query(
      `INSERT INTO users (id, full_name, student_id, instructor_id, role, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (id) DO UPDATE
       SET full_name = EXCLUDED.full_name,
           student_id = EXCLUDED.student_id,
           instructor_id = EXCLUDED.instructor_id,
           updated_at = EXCLUDED.updated_at
       RETURNING *`,
      [
        user.id,
        user.fullName,
        user.studentId || null,
        user.instructorId || null,
        user.role,
        user.createdAt,
        user.createdAt
      ]
    );
    return result.rows[0];
  },

  findById: async (userId) => {
    const result = await query(
      'SELECT * FROM users WHERE id = $1',
      [userId]
    );
    return result.rows[0];
  },

  findByStudentId: async (studentId) => {
    const result = await query(
      'SELECT * FROM users WHERE student_id = $1',
      [studentId]
    );
    return result.rows[0];
  },

  findByInstructorId: async (instructorId) => {
    const result = await query(
      'SELECT * FROM users WHERE instructor_id = $1',
      [instructorId]
    );
    return result.rows[0];
  }
};

// Session operations
const sessionQueries = {
  create: async (session) => {
    const result = await query(
      `INSERT INTO sessions (id, room_name, instructor_id, started_at, participant_count, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        session.id,
        session.roomName,
        session.instructorId,
        session.startedAt,
        session.participantCount || 0,
        JSON.stringify(session.metadata || {})
      ]
    );
    return result.rows[0];
  },

  findById: async (sessionId) => {
    const result = await query(
      'SELECT * FROM sessions WHERE id = $1',
      [sessionId]
    );
    return result.rows[0];
  },

  findByRoomName: async (roomName) => {
    const result = await query(
      'SELECT * FROM sessions WHERE room_name = $1 AND ended_at IS NULL ORDER BY started_at DESC LIMIT 1',
      [roomName]
    );
    return result.rows[0];
  },

  updateParticipantCount: async (sessionId, count) => {
    const result = await query(
      'UPDATE sessions SET participant_count = $1 WHERE id = $2 RETURNING *',
      [count, sessionId]
    );
    return result.rows[0];
  },

  endSession: async (sessionId) => {
    const result = await query(
      'UPDATE sessions SET ended_at = $1 WHERE id = $2 RETURNING *',
      [new Date().toISOString(), sessionId]
    );
    return result.rows[0];
  }
};

// Evaluation operations
const evaluationQueries = {
  create: async (evaluation) => {
    const result = await query(
      `INSERT INTO evaluations (id, session_id, student_id, instructor_id, score, notes, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        evaluation.id,
        evaluation.sessionId,
        evaluation.studentId,
        evaluation.instructorId,
        evaluation.score,
        evaluation.notes || null,
        evaluation.createdAt,
        evaluation.createdAt
      ]
    );
    return result.rows[0];
  },

  findByStudent: async (studentId, sessionId = null) => {
    if (sessionId) {
      const result = await query(
        'SELECT * FROM evaluations WHERE student_id = $1 AND session_id = $2',
        [studentId, sessionId]
      );
      return result.rows[0];
    } else {
      const result = await query(
        'SELECT * FROM evaluations WHERE student_id = $1 ORDER BY created_at DESC',
        [studentId]
      );
      return result.rows;
    }
  }
};

// Block operations
const blockQueries = {
  create: async (block) => {
    const result = await query(
      `INSERT INTO blocks (id, session_id, student_id, instructor_id, duration, reason, created_at, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        block.id,
        block.sessionId,
        block.studentId,
        block.instructorId,
        block.duration,
        block.reason || null,
        block.createdAt,
        block.expiresAt
      ]
    );
    return result.rows[0];
  },

  isBlocked: async (studentId, sessionId = null) => {
    const now = new Date().toISOString();
    let queryText = 'SELECT * FROM blocks WHERE student_id = $1 AND (expires_at IS NULL OR expires_at > $2)';
    const params = [studentId, now];

    if (sessionId) {
      queryText += ' AND session_id = $3';
      params.push(sessionId);
    }

    const result = await query(queryText, params);
    return result.rows.length > 0 ? result.rows[0] : null;
  }
};

// Chat message operations
const chatQueries = {
  create: async (message) => {
    const result = await query(
      `INSERT INTO chat_messages (id, session_id, sender_id, sender_name, content, message_type, is_from_instructor, timestamp)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        message.id,
        message.sessionId,
        message.senderId,
        message.senderName,
        message.content,
        message.messageType || 'text',
        message.isFromInstructor || false,
        message.timestamp
      ]
    );
    return result.rows[0];
  },

  findBySession: async (sessionId, limit = 100) => {
    const result = await query(
      'SELECT * FROM chat_messages WHERE session_id = $1 ORDER BY timestamp DESC LIMIT $2',
      [sessionId, limit]
    );
    return result.rows;
  }
};

// Hand raise operations
const handRaiseQueries = {
  create: async (handRaise) => {
    const result = await query(
      `INSERT INTO hand_raises (id, session_id, student_id, raised_at, is_active)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        handRaise.id,
        handRaise.sessionId,
        handRaise.studentId,
        handRaise.raisedAt,
        true
      ]
    );
    return result.rows[0];
  },

  lower: async (sessionId, studentId) => {
    const result = await query(
      `UPDATE hand_raises
       SET is_active = false, lowered_at = $1
       WHERE session_id = $2 AND student_id = $3 AND is_active = true
       RETURNING *`,
      [new Date().toISOString(), sessionId, studentId]
    );
    return result.rows[0];
  },

  findBySession: async (sessionId, activeOnly = true) => {
    let queryText = 'SELECT * FROM hand_raises WHERE session_id = $1';
    if (activeOnly) {
      queryText += ' AND is_active = true';
    }
    queryText += ' ORDER BY raised_at DESC';

    const result = await query(queryText, [sessionId]);
    return result.rows;
  }
};

module.exports = {
  pool,
  query,
  transaction,
  userQueries,
  sessionQueries,
  evaluationQueries,
  blockQueries,
  chatQueries,
  handRaiseQueries
};
