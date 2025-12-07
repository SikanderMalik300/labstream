# LabStream Database Schema Documentation

## Overview
This document provides a comprehensive description of the LabStream database schema, including table structures, relationships, and field explanations.

## Database: `labstream`
**Database Management System:** PostgreSQL 16+

---

## Tables

### 1. `users`
Stores information about all users (students and instructors) in the system.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique identifier for each user |
| `full_name` | VARCHAR(255) | NOT NULL | User's full name |
| `university_id` | VARCHAR(100) | NULL | University ID (required for students, NULL for instructors) |
| `role` | VARCHAR(20) | NOT NULL, CHECK IN ('student', 'instructor') | User role in the system |
| `created_at` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | Timestamp when user was created |
| `updated_at` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | Timestamp when user was last updated |

**Constraints:**
- Students MUST have a `university_id` (CHECK constraint)
- Instructors have NULL `university_id`

**Indexes:**
- `idx_users_role` on `role`
- `idx_users_university_id` on `university_id`

---

### 2. `sessions`
Represents exam or class sessions conducted by instructors.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique session identifier |
| `room_name` | VARCHAR(255) | NOT NULL, UNIQUE | LiveKit room name |
| `instructor_id` | UUID | NOT NULL, FOREIGN KEY -> users(id) | Instructor who created the session |
| `started_at` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | Session start time |
| `ended_at` | TIMESTAMP WITH TIME ZONE | NULL | Session end time (NULL if active) |
| `participant_count` | INTEGER | DEFAULT 0, CHECK >= 0 | Number of participants |
| `metadata` | JSONB | NULL | Additional session metadata |

**Relationships:**
- `instructor_id` references `users(id)` (CASCADE DELETE)

**Indexes:**
- `idx_sessions_instructor` on `instructor_id`
- `idx_sessions_room_name` on `room_name`
- `idx_sessions_started_at` on `started_at`

---

### 3. `session_participants`
Tracks which users participated in which sessions (many-to-many relationship).

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique record identifier |
| `session_id` | UUID | NOT NULL, FOREIGN KEY -> sessions(id) | Session identifier |
| `user_id` | UUID | NOT NULL, FOREIGN KEY -> users(id) | User identifier |
| `joined_at` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | When user joined the session |
| `left_at` | TIMESTAMP WITH TIME ZONE | NULL | When user left (NULL if still in session) |

**Constraints:**
- UNIQUE constraint on `(session_id, user_id)` - prevents duplicate entries

**Relationships:**
- `session_id` references `sessions(id)` (CASCADE DELETE)
- `user_id` references `users(id)` (CASCADE DELETE)

**Indexes:**
- `idx_session_participants_session` on `session_id`
- `idx_session_participants_user` on `user_id`

---

### 4. `blocks`
Records when students are blocked from joining sessions.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique block identifier |
| `session_id` | UUID | NOT NULL, FOREIGN KEY -> sessions(id) | Session where block was issued |
| `student_id` | UUID | NOT NULL, FOREIGN KEY -> users(id) | Blocked student |
| `instructor_id` | UUID | NOT NULL, FOREIGN KEY -> users(id) | Instructor who issued the block |
| `duration` | VARCHAR(20) | NOT NULL, CHECK IN ('minutes10', 'minutes30', 'permanent') | Block duration type |
| `reason` | TEXT | NULL | Reason for blocking |
| `created_at` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | When block was created |
| `expires_at` | TIMESTAMP WITH TIME ZONE | NULL | When block expires (NULL for permanent) |

**Constraints:**
- Permanent blocks MUST have NULL `expires_at` (CHECK constraint)
- Temporary blocks have calculated `expires_at`

**Relationships:**
- `session_id` references `sessions(id)` (CASCADE DELETE)
- `student_id` references `users(id)` (CASCADE DELETE)
- `instructor_id` references `users(id)` (CASCADE DELETE)

**Indexes:**
- `idx_blocks_student` on `student_id`
- `idx_blocks_session` on `session_id`
- `idx_blocks_expires_at` on `expires_at`

---

### 5. `evaluations`
Stores instructor evaluations of student performance in sessions.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique evaluation identifier |
| `session_id` | UUID | NOT NULL, FOREIGN KEY -> sessions(id) | Session being evaluated |
| `student_id` | UUID | NOT NULL, FOREIGN KEY -> users(id) | Student being evaluated |
| `instructor_id` | UUID | NOT NULL, FOREIGN KEY -> users(id) | Instructor who evaluated |
| `score` | DECIMAL(4, 2) | NOT NULL, CHECK 0-10 | Evaluation score (0.00 to 10.00) |
| `notes` | TEXT | NULL | Evaluation notes/comments |
| `created_at` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | When evaluation was created |
| `updated_at` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | When evaluation was last updated |

**Constraints:**
- Score must be between 0 and 10 (CHECK constraint)
- UNIQUE constraint on `(session_id, student_id)` - one evaluation per student per session

**Relationships:**
- `session_id` references `sessions(id)` (CASCADE DELETE)
- `student_id` references `users(id)` (CASCADE DELETE)
- `instructor_id` references `users(id)` (CASCADE DELETE)

**Indexes:**
- `idx_evaluations_student` on `student_id`
- `idx_evaluations_session` on `session_id`

**Triggers:**
- `update_evaluations_updated_at` - automatically updates `updated_at` on modification

---

### 6. `chat_messages`
Stores all chat messages sent during sessions.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique message identifier |
| `session_id` | UUID | FOREIGN KEY -> sessions(id) | Session where message was sent |
| `sender_id` | UUID | NOT NULL, FOREIGN KEY -> users(id) | User who sent the message |
| `sender_name` | VARCHAR(255) | NOT NULL | Name of sender (for display) |
| `content` | TEXT | NOT NULL | Message content |
| `message_type` | VARCHAR(20) | NOT NULL, CHECK IN ('text', 'system', 'handRaise', 'handLower') | Type of message |
| `is_from_instructor` | BOOLEAN | DEFAULT FALSE | Whether sender is an instructor |
| `timestamp` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | When message was sent |

**Relationships:**
- `session_id` references `sessions(id)` (CASCADE DELETE)
- `sender_id` references `users(id)` (CASCADE DELETE)

**Indexes:**
- `idx_chat_messages_session` on `session_id`
- `idx_chat_messages_timestamp` on `timestamp`

---

### 7. `hand_raises`
Tracks active and historical hand raises by students.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique hand raise identifier |
| `session_id` | UUID | NOT NULL, FOREIGN KEY -> sessions(id) | Session where hand was raised |
| `student_id` | UUID | NOT NULL, FOREIGN KEY -> users(id) | Student who raised hand |
| `raised_at` | TIMESTAMP WITH TIME ZONE | DEFAULT NOW() | When hand was raised |
| `lowered_at` | TIMESTAMP WITH TIME ZONE | NULL | When hand was lowered (NULL if still raised) |
| `is_active` | BOOLEAN | DEFAULT TRUE | Whether hand is currently raised |

**Constraints:**
- UNIQUE constraint on `(session_id, student_id, is_active)` - prevents duplicate active raises

**Relationships:**
- `session_id` references `sessions(id)` (CASCADE DELETE)
- `student_id` references `users(id)` (CASCADE DELETE)

**Indexes:**
- `idx_hand_raises_session` on `session_id`
- `idx_hand_raises_is_active` on `is_active`

---

## Entity Relationship Diagram (ERD)

```
┌─────────────┐
│    users    │
│─────────────│
│ id (PK)     │
│ full_name   │
│ university_id│
│ role        │
│ created_at  │
│ updated_at  │
└─────────────┘
      │
      │ 1:N (instructor)
      ▼
┌─────────────────┐          ┌──────────────────────┐
│    sessions     │◄─────────│ session_participants │
│─────────────────│   1:N    │──────────────────────│
│ id (PK)         │          │ id (PK)              │
│ room_name       │          │ session_id (FK)      │
│ instructor_id(FK)│         │ user_id (FK)         │
│ started_at      │          │ joined_at            │
│ ended_at        │          │ left_at              │
│ participant_count│         └──────────────────────┘
│ metadata        │                  ▲
└─────────────────┘                  │ N:1
      │                              │
      │ 1:N                   ┌─────────────┐
      ├───────────────────────┤    users    │
      │                       └─────────────┘
      │
      ├─────────────┐
      │             │
      │ 1:N         │ 1:N
      ▼             ▼
┌─────────────┐   ┌──────────────┐
│   blocks    │   │ evaluations  │
│─────────────│   │──────────────│
│ id (PK)     │   │ id (PK)      │
│ session_id  │   │ session_id   │
│ student_id  │   │ student_id   │
│ instructor_id│  │ instructor_id│
│ duration    │   │ score        │
│ reason      │   │ notes        │
│ created_at  │   │ created_at   │
│ expires_at  │   │ updated_at   │
└─────────────┘   └──────────────┘

      │ 1:N                   │ 1:N
      ▼                       ▼
┌──────────────┐      ┌──────────────┐
│chat_messages │      │ hand_raises  │
│──────────────│      │──────────────│
│ id (PK)      │      │ id (PK)      │
│ session_id   │      │ session_id   │
│ sender_id    │      │ student_id   │
│ sender_name  │      │ raised_at    │
│ content      │      │ lowered_at   │
│ message_type │      │ is_active    │
│ timestamp    │      └──────────────┘
└──────────────┘
```

## Key Relationships

1. **Users ↔ Sessions**: One instructor can create many sessions (1:N)
2. **Sessions ↔ Session Participants**: Many-to-many through `session_participants`
3. **Sessions ↔ Blocks**: One session can have many blocks (1:N)
4. **Sessions ↔ Evaluations**: One session can have many evaluations (1:N)
5. **Sessions ↔ Chat Messages**: One session can have many messages (1:N)
6. **Sessions ↔ Hand Raises**: One session can have many hand raises (1:N)

## Database Functions & Triggers

### `update_updated_at_column()`
Automatically updates the `updated_at` timestamp when a record is modified.

**Used by:**
- `evaluations` table
- `users` table

---

## Notes

- All tables use UUID as primary keys for better distribution and security
- Timestamps use `TIMESTAMP WITH TIME ZONE` for proper timezone handling
- Foreign key relationships use `CASCADE DELETE` to maintain referential integrity
- Indexes are created on frequently queried fields for performance optimization
- CHECK constraints ensure data integrity at the database level
