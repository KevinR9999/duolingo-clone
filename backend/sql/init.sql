-- ===========================================================
-- PostgreSQL Database Schema
-- Compatible and executable version of your provided structure
-- ===========================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===========================================================
-- Table: users
-- ===========================================================
CREATE TABLE public.users (
  uid uuid NOT NULL DEFAULT uuid_generate_v4(),
  email character varying NOT NULL UNIQUE,
  display_name character varying NOT NULL,
  password text NOT NULL, -- 🔐 Campo agregado para login
  photo_url text,
  level character varying NOT NULL DEFAULT 'A1'::character varying
    CHECK (level::text = ANY (ARRAY['A1','A2','B1','B2']::text[])),
  total_xp integer NOT NULL DEFAULT 0,
  current_streak integer NOT NULL DEFAULT 0,
  max_streak integer NOT NULL DEFAULT 0,
  lessons_completed integer NOT NULL DEFAULT 0,
  accuracy numeric DEFAULT 0.00
    CHECK (accuracy >= 0::numeric AND accuracy <= 100::numeric),
  total_study_time integer DEFAULT 0,
  settings jsonb DEFAULT '{}'::jsonb,
  friends_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  last_active timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (uid)
);

-- ===========================================================
-- Table: lessons
-- ===========================================================
CREATE TABLE public.lessons (
  lesson_id character varying NOT NULL,
  title character varying NOT NULL,
  level character varying NOT NULL
    CHECK (level::text = ANY (ARRAY['A1','A2','B1','B2']::text[])),
  order_number integer NOT NULL,
  description text,
  content jsonb NOT NULL,
  vocabulary jsonb,
  media jsonb,
  xp_reward integer NOT NULL DEFAULT 100,
  duration integer,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT lessons_pkey PRIMARY KEY (lesson_id)
);

-- ===========================================================
-- Table: achievements
-- ===========================================================
CREATE TABLE public.achievements (
  achievement_id character varying NOT NULL,
  name character varying NOT NULL,
  description text,
  icon character varying NOT NULL,
  xp_reward integer NOT NULL DEFAULT 50,
  rarity character varying
    CHECK (rarity::text = ANY (ARRAY['common','rare','epic','legendary']::text[])),
  criteria jsonb NOT NULL,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT achievements_pkey PRIMARY KEY (achievement_id)
);

-- ===========================================================
-- Table: exercises
-- ===========================================================
CREATE TABLE public.exercises (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  lesson_id character varying NOT NULL,
  order_number integer NOT NULL,
  type character varying NOT NULL
    CHECK (type::text = ANY (ARRAY[
      'flashcard','multiple_choice','listening',
      'speaking','word_order','fill_blank','matching'
    ]::text[])),
  question text NOT NULL,
  options jsonb,
  correct_answer text NOT NULL,
  explanation text,
  points integer NOT NULL DEFAULT 10,
  difficulty character varying
    CHECK (difficulty::text = ANY (ARRAY['easy','medium','hard']::text[])),
  media_url text,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT exercises_pkey PRIMARY KEY (id),
  CONSTRAINT exercises_lesson_id_fkey FOREIGN KEY (lesson_id)
    REFERENCES public.lessons(lesson_id)
);

-- ===========================================================
-- Table: fcm_tokens
-- ===========================================================
CREATE TABLE public.fcm_tokens (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  token text NOT NULL UNIQUE,
  device_type character varying
    CHECK (device_type::text = ANY (ARRAY['android','ios','web']::text[])),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT fcm_tokens_pkey PRIMARY KEY (id),
  CONSTRAINT fcm_tokens_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(uid)
);

-- ===========================================================
-- Table: friendships
-- ===========================================================
CREATE TABLE public.friendships (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  friend_id uuid NOT NULL,
  status character varying NOT NULL DEFAULT 'pending'
    CHECK (status::text = ANY (ARRAY['pending','accepted','rejected']::text[])),
  friend_data jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT friendships_pkey PRIMARY KEY (id),
  CONSTRAINT friendships_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(uid),
  CONSTRAINT friendships_friend_id_fkey FOREIGN KEY (friend_id)
    REFERENCES public.users(uid)
);

-- ===========================================================
-- Table: notifications
-- ===========================================================
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  type character varying NOT NULL
    CHECK (type::text = ANY (ARRAY[
      'daily_reminder','streak_alert','achievement',
      'new_lesson','friend_activity'
    ]::text[])),
  title character varying NOT NULL,
  body text,
  data jsonb,
  read boolean DEFAULT false,
  sent_at timestamptz DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(uid)
);

-- ===========================================================
-- Table: rankings
-- ===========================================================
CREATE TABLE public.rankings (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  period_type character varying NOT NULL
    CHECK (period_type::text = ANY (ARRAY['weekly','monthly']::text[])),
  period_start date NOT NULL,
  period_end date NOT NULL,
  xp integer NOT NULL DEFAULT 0,
  rank integer,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT rankings_pkey PRIMARY KEY (id),
  CONSTRAINT rankings_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(uid)
);

-- ===========================================================
-- Table: test_results
-- ===========================================================
CREATE TABLE public.test_results (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL UNIQUE,
  score integer NOT NULL CHECK (score >= 0 AND score <= 20),
  level character varying NOT NULL
    CHECK (level::text = ANY (ARRAY['A1','A2','B1','B2']::text[])),
  percentage numeric CHECK (percentage >= 0::numeric AND percentage <= 100::numeric),
  answers jsonb NOT NULL,
  category_scores jsonb,
  duration integer,
  completed_at timestamptz DEFAULT now(),
  CONSTRAINT test_results_pkey PRIMARY KEY (id),
  CONSTRAINT test_results_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(uid)
);

-- ===========================================================
-- Table: user_achievements
-- ===========================================================
CREATE TABLE public.user_achievements (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  achievement_id character varying NOT NULL,
  xp_earned integer NOT NULL,
  unlocked_at timestamptz DEFAULT now(),
  CONSTRAINT user_achievements_pkey PRIMARY KEY (id),
  CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(uid),
  CONSTRAINT user_achievements_achievement_id_fkey FOREIGN KEY (achievement_id)
    REFERENCES public.achievements(achievement_id)
);

-- ===========================================================
-- Table: user_progress
-- ===========================================================
CREATE TABLE public.user_progress (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  lesson_id character varying NOT NULL,
  status character varying NOT NULL DEFAULT 'not_started'
    CHECK (status::text = ANY (ARRAY['not_started','in_progress','completed']::text[])),
  exercises_total integer DEFAULT 0,
  exercises_completed integer DEFAULT 0,
  exercises_correct integer DEFAULT 0,
  score numeric DEFAULT 0.00 CHECK (score >= 0 AND score <= 100),
  accuracy numeric DEFAULT 0.00 CHECK (accuracy >= 0 AND accuracy <= 100),
  xp_earned integer DEFAULT 0,
  time_spent integer DEFAULT 0,
  exercise_results jsonb,
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT user_progress_pkey PRIMARY KEY (id),
  CONSTRAINT user_progress_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.users(uid),
  CONSTRAINT user_progress_lesson_id_fkey FOREIGN KEY (lesson_id)
    REFERENCES public.lessons(lesson_id)
);
