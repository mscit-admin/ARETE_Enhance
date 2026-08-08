-- ARETE database schema (PostgreSQL)
-- Idempotent: safe to run repeatedly in development.

CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- for gen_random_uuid()

-- ---------- Enums ----------
DO $$ BEGIN
  CREATE TYPE user_role     AS ENUM ('member','trainer','admin');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE user_status   AS ENUM ('active','suspended');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE fitness_goal  AS ENUM ('lose_weight','build_muscle','endurance','general_fitness');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE experience_level AS ENUM ('beginner','intermediate','advanced');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE unit_system   AS ENUM ('metric','imperial');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE membership_tier   AS ENUM ('basic','silver','gold','elite');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE membership_status AS ENUM ('active','expired','frozen');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('paid','pending','refunded','failed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE session_status AS ENUM ('booked','completed','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------- Identity ----------
CREATE TABLE IF NOT EXISTS users (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email          text NOT NULL UNIQUE,
  password_hash  text NOT NULL,
  full_name      text NOT NULL,
  role           user_role   NOT NULL DEFAULT 'member',
  status         user_status NOT NULL DEFAULT 'active',
  phone          text,
  photo_url      text,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trainers (
  user_id         uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  specialty       text,
  bio             text,
  certifications  text[] NOT NULL DEFAULT '{}',
  rating          numeric(3,2) NOT NULL DEFAULT 0,
  avg_response_h  int NOT NULL DEFAULT 24,
  code            text UNIQUE
);
-- Ensure the QR link code exists on pre-existing installs.
ALTER TABLE trainers ADD COLUMN IF NOT EXISTS code text UNIQUE;

CREATE TABLE IF NOT EXISTS members (
  user_id               uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  gender                text,
  date_of_birth         date,
  goal                  fitness_goal,
  experience            experience_level,
  units                 unit_system NOT NULL DEFAULT 'metric',
  height_cm             numeric(5,1),
  weight_kg             numeric(5,1),
  body_fat_pct          numeric(4,1),
  current_streak_days   int NOT NULL DEFAULT 0,
  weekly_target_sessions int NOT NULL DEFAULT 3,
  trainer_id            uuid REFERENCES trainers(user_id) ON DELETE SET NULL,
  joined_on             date NOT NULL DEFAULT current_date
);

-- ---------- Billing ----------
CREATE TABLE IF NOT EXISTS memberships (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   uuid NOT NULL REFERENCES members(user_id) ON DELETE CASCADE,
  tier        membership_tier   NOT NULL,
  status      membership_status NOT NULL DEFAULT 'active',
  started_on  date NOT NULL DEFAULT current_date,
  renews_on   date NOT NULL,
  price       numeric(8,2) NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_memberships_member ON memberships(member_id);
CREATE INDEX IF NOT EXISTS idx_memberships_status ON memberships(status);

CREATE TABLE IF NOT EXISTS payments (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id     uuid NOT NULL REFERENCES members(user_id) ON DELETE CASCADE,
  membership_id uuid REFERENCES memberships(id) ON DELETE SET NULL,
  amount        numeric(8,2) NOT NULL,
  currency      text NOT NULL DEFAULT 'USD',
  method        text,
  status        payment_status NOT NULL DEFAULT 'paid',
  paid_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at);

-- ---------- Content ----------
CREATE TABLE IF NOT EXISTS plans (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  split         text,
  days_per_week int NOT NULL,
  weeks         int NOT NULL DEFAULT 8,
  goal          fitness_goal,
  experience    experience_level,
  equipment     text[] NOT NULL DEFAULT '{}',
  avg_minutes   int NOT NULL DEFAULT 45,
  description   text,
  created_by    uuid REFERENCES trainers(user_id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS exercises (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  muscle_group  text,
  equipment     text,
  rest_seconds  int NOT NULL DEFAULT 60,
  video_url     text
);

CREATE TABLE IF NOT EXISTS plan_exercises (
  plan_id      uuid NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  exercise_id  uuid NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  day_index    int NOT NULL DEFAULT 0,
  position     int NOT NULL DEFAULT 0,
  target_sets  int NOT NULL DEFAULT 3,
  target_reps  int NOT NULL DEFAULT 10,
  PRIMARY KEY (plan_id, exercise_id, day_index)
);

CREATE TABLE IF NOT EXISTS plan_assignments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   uuid NOT NULL REFERENCES members(user_id) ON DELETE CASCADE,
  plan_id     uuid NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  assigned_by uuid REFERENCES trainers(user_id) ON DELETE SET NULL,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  active      boolean NOT NULL DEFAULT true
);

-- ---------- Activity ----------
CREATE TABLE IF NOT EXISTS workout_sessions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id    uuid NOT NULL REFERENCES members(user_id) ON DELETE CASCADE,
  plan_id      uuid REFERENCES plans(id) ON DELETE SET NULL,
  title        text,
  started_at   timestamptz NOT NULL DEFAULT now(),
  finished_at  timestamptz,
  total_volume numeric(10,1) NOT NULL DEFAULT 0,
  pr_count     int NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_sessions_member ON workout_sessions(member_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started ON workout_sessions(started_at);

CREATE TABLE IF NOT EXISTS set_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  uuid NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id uuid REFERENCES exercises(id) ON DELETE SET NULL,
  set_number  int NOT NULL,
  weight_kg   numeric(6,2) NOT NULL,
  reps        int NOT NULL,
  is_pr       boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS body_measurements (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id    uuid NOT NULL REFERENCES members(user_id) ON DELETE CASCADE,
  taken_on     date NOT NULL DEFAULT current_date,
  weight_kg    numeric(5,1),
  waist_cm     numeric(5,1),
  chest_cm     numeric(5,1),
  arms_cm      numeric(5,1),
  body_fat_pct numeric(4,1)
);

CREATE TABLE IF NOT EXISTS daily_stats (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id      uuid NOT NULL REFERENCES members(user_id) ON DELETE CASCADE,
  stat_date      date NOT NULL DEFAULT current_date,
  water_glasses  int NOT NULL DEFAULT 0,
  water_target   int NOT NULL DEFAULT 8,
  steps          int NOT NULL DEFAULT 0,
  steps_target   int NOT NULL DEFAULT 8000,
  calories       int NOT NULL DEFAULT 0,
  calories_target int NOT NULL DEFAULT 500,
  active_minutes int NOT NULL DEFAULT 0,
  UNIQUE (member_id, stat_date)
);

-- ---------- Coaching ----------
CREATE TABLE IF NOT EXISTS coach_sessions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   uuid NOT NULL REFERENCES members(user_id) ON DELETE CASCADE,
  trainer_id  uuid REFERENCES trainers(user_id) ON DELETE SET NULL,
  start_at    timestamptz NOT NULL,
  minutes     int NOT NULL DEFAULT 45,
  focus       text,
  status      session_status NOT NULL DEFAULT 'booked'
);
CREATE INDEX IF NOT EXISTS idx_coach_sessions_start ON coach_sessions(start_at);

CREATE TABLE IF NOT EXISTS messages (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   uuid NOT NULL REFERENCES members(user_id) ON DELETE CASCADE,
  trainer_id  uuid REFERENCES trainers(user_id) ON DELETE SET NULL,
  from_coach  boolean NOT NULL,
  body        text NOT NULL,
  kind        text NOT NULL DEFAULT 'text',
  plan_id     uuid REFERENCES plans(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ---------- Security ----------
CREATE TABLE IF NOT EXISTS audit_log (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id   uuid REFERENCES users(id) ON DELETE SET NULL,
  action     text NOT NULL,
  entity     text NOT NULL,
  entity_id  uuid,
  at         timestamptz NOT NULL DEFAULT now()
);

-- ---------- Admin console settings & localization ----------
-- Simple key/value store for global admin settings (e.g. currency).
CREATE TABLE IF NOT EXISTS app_settings (
  key         text PRIMARY KEY,
  value       text,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Custom admin-console languages added via the CSV importer. The three base
-- languages (en/ar/fr) ship in the web client; only extra languages live here.
CREATE TABLE IF NOT EXISTS admin_locales (
  code        text PRIMARY KEY,                 -- e.g. 'es', 'tr'
  name        text NOT NULL,                    -- display name, e.g. 'Español'
  dir         text NOT NULL DEFAULT 'ltr',      -- 'ltr' | 'rtl'
  strings     jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Per-user admin-console permissions (NULL for a full-access admin).
ALTER TABLE users ADD COLUMN IF NOT EXISTS permissions jsonb;
