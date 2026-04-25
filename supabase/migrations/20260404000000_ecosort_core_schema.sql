-- =============================================================================
-- EcoSort by Bao — Supabase (PostgreSQL + PostGIS) core schema
-- Aligns with Flutter: 10 AI labels, 4 waste groups, gamification, GIS, admin.
-- =============================================================================

-- Extensions (Supabase: enable PostGIS in Dashboard → Database → Extensions)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- -----------------------------------------------------------------------------
-- Enums
-- -----------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('user', 'admin', 'super_admin');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.submission_status AS ENUM (
    'pending_review',
    'approved',
    'rejected',
    'merged_existing'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.privileged_action_type AS ENUM (
    'delete_collection_point',
    'promote_user_admin',
    'demote_admin',
    'purge_user_data',
    'toggle_kill_switch',
    'other'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.privileged_action_state AS ENUM (
    'draft',
    'awaiting_second_approval',
    'approved',
    'rejected',
    'executed',
    'expired'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- -----------------------------------------------------------------------------
-- Profiles (1:1 auth.users) — levels & gamification aggregates
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name text,
  avatar_url text,
  locale text DEFAULT 'vi',
  role public.app_role NOT NULL DEFAULT 'user',
  -- XP drives level; level cached for fast reads (updated by trigger)
  xp_total bigint NOT NULL DEFAULT 0 CHECK (xp_total >= 0),
  level int NOT NULL DEFAULT 1 CHECK (level >= 1),
  scan_count int NOT NULL DEFAULT 0 CHECK (scan_count >= 0),
  is_locked boolean NOT NULL DEFAULT false,
  locked_reason text,
  locked_at timestamptz,
  locked_by uuid REFERENCES auth.users (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT profiles_admin_lock CHECK (
    (is_locked = false AND locked_reason IS NULL AND locked_at IS NULL AND locked_by IS NULL)
    OR (is_locked = true)
  )
);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles (role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_locked ON public.profiles (is_locked) WHERE is_locked = true;

-- -----------------------------------------------------------------------------
-- System settings + kill switch (read by RLS / RPC; admin writes audited)
-- Keys are stable; values flexible via JSONB (maintenance, point ratios, metadata)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.system_settings (
  key text PRIMARY KEY,
  value jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users (id)
);

INSERT INTO public.system_settings (key, value)
VALUES
  ('maintenance', '{"enabled": false, "kill_switch": false, "message": ""}'::jsonb),
  ('points', '{"scan_base": 10, "game_correct": 5, "streak_bonus_per": 1}'::jsonb),
  ('gemini', '{"model": "gemini-flash-latest"}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Waste taxonomy: 4 groups (matches WasteCategory in Flutter) + 10 base labels
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.waste_groups (
  id smallserial PRIMARY KEY,
  code text NOT NULL UNIQUE,
  name_vi text NOT NULL,
  sort_order smallint NOT NULL DEFAULT 0
);

INSERT INTO public.waste_groups (code, name_vi, sort_order) VALUES
  ('recyclable', 'Tái chế', 1),
  ('organic', 'Hữu cơ', 2),
  ('hazardous', 'Nguy hại', 3),
  ('trash', 'Không tái chế / Khác', 4)
ON CONFLICT (code) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.ai_model_classes (
  id smallserial PRIMARY KEY,
  label text NOT NULL UNIQUE,
  default_group_id smallint REFERENCES public.waste_groups (id),
  description text
);

INSERT INTO public.ai_model_classes (label, default_group_id, description) VALUES
  ('battery', (SELECT id FROM public.waste_groups WHERE code = 'hazardous'), 'Pin'),
  ('biological', (SELECT id FROM public.waste_groups WHERE code = 'organic'), 'Sinh học'),
  ('cardboard', (SELECT id FROM public.waste_groups WHERE code = 'recyclable'), 'Bìa carton'),
  ('clothes', (SELECT id FROM public.waste_groups WHERE code = 'trash'), 'Quần áo'),
  ('glass', (SELECT id FROM public.waste_groups WHERE code = 'recyclable'), 'Thủy tinh'),
  ('metal', (SELECT id FROM public.waste_groups WHERE code = 'recyclable'), 'Kim loại'),
  ('paper', (SELECT id FROM public.waste_groups WHERE code = 'recyclable'), 'Giấy'),
  ('plastic', (SELECT id FROM public.waste_groups WHERE code = 'recyclable'), 'Nhựa'),
  ('shoes', (SELECT id FROM public.waste_groups WHERE code = 'trash'), 'Giày dép'),
  ('trash', (SELECT id FROM public.waste_groups WHERE code = 'trash'), 'Rác hỗn hợp')
ON CONFLICT (label) DO NOTHING;

-- Official dictionary (post-approval). Fun facts + image URL as required.
CREATE TABLE IF NOT EXISTS public.waste_dictionary (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name_vi text NOT NULL,
  description text,
  fun_fact text,
  image_url text,
  waste_group_id smallint NOT NULL REFERENCES public.waste_groups (id),
  ai_model_class_id smallint REFERENCES public.ai_model_classes (id),
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_waste_dictionary_group ON public.waste_dictionary (waste_group_id);
CREATE INDEX IF NOT EXISTS idx_waste_dictionary_active ON public.waste_dictionary (is_active) WHERE is_active = true;

-- -----------------------------------------------------------------------------
-- User contributions → review queue → promote to waste_dictionary + game content
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.waste_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submitter_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  status public.submission_status NOT NULL DEFAULT 'pending_review',
  -- AI / Gemini pipeline snapshot
  tflite_top_label text,
  tflite_confidence numeric(6,5),
  gemini_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  suggested_name_vi text,
  suggested_group_id smallint REFERENCES public.waste_groups (id),
  suggested_fun_fact text,
  suggested_image_url text,
  scan_image_path text,
  reviewer_id uuid REFERENCES auth.users (id),
  reviewed_at timestamptz,
  rejection_reason text,
  merged_dictionary_id uuid REFERENCES public.waste_dictionary (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_waste_submissions_status ON public.waste_submissions (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_waste_submissions_submitter ON public.waste_submissions (submitter_id);

-- Game questions: flexible JSONB per type (quiz / sorting / ar); links dictionary entry
CREATE TABLE IF NOT EXISTS public.game_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  waste_dictionary_id uuid NOT NULL REFERENCES public.waste_dictionary (id) ON DELETE CASCADE,
  game_types text[] NOT NULL DEFAULT ARRAY['quiz']::text[],
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_game_questions_dictionary ON public.game_questions (waste_dictionary_id);
CREATE INDEX IF NOT EXISTS idx_game_questions_gin ON public.game_questions USING gin (game_types);
CREATE INDEX IF NOT EXISTS idx_game_questions_payload ON public.game_questions USING gin (payload jsonb_path_ops);

-- -----------------------------------------------------------------------------
-- GIS: curated collection points (WGS84 geography for meter-accurate ST_DWithin)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.collection_points (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  location geography(Point, 4326) NOT NULL,
  address text,
  point_type text,
  external_ref text,
  is_verified boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES auth.users (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_collection_points_location
  ON public.collection_points USING gist (location);
CREATE INDEX IF NOT EXISTS idx_collection_points_verified ON public.collection_points (is_verified);

-- -----------------------------------------------------------------------------
-- Point ledger (append-only integrity) + optional scan/game attribution
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.point_ledger (
  id bigserial PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  delta int NOT NULL,
  reason text NOT NULL,
  ref_type text,
  ref_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_point_ledger_user_time ON public.point_ledger (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.user_scan_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  waste_dictionary_id uuid REFERENCES public.waste_dictionary (id),
  ai_label text,
  confidence numeric(6,5),
  earned_xp int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_scan_events_user ON public.user_scan_events (user_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- Game sessions: one row per play; JSONB holds per-type stats (timer, streak, AR…)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.game_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  game_type text NOT NULL,
  score int NOT NULL DEFAULT 0 CHECK (score >= 0),
  duration_ms int,
  detail jsonb NOT NULL DEFAULT '{}'::jsonb,
  started_at timestamptz,
  finished_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_game_sessions_user_time ON public.game_sessions (user_id, finished_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_sessions_type ON public.game_sessions (game_type);

-- -----------------------------------------------------------------------------
-- Badges (configurable) + user unlocks
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name_vi text NOT NULL,
  description text,
  threshold_xp int,
  icon_key text,
  sort_order int NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.user_badges (
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  badge_id uuid NOT NULL REFERENCES public.badges (id) ON DELETE CASCADE,
  unlocked_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, badge_id)
);

-- Seed badges aligned with GameProvider (thresholds adjustable in DB)
INSERT INTO public.badges (code, name_vi, threshold_xp, icon_key, sort_order) VALUES
  ('mam_xanh', 'Mầm Xanh', 50, '🌱', 1),
  ('chien_binh_eco', 'Chiến binh Eco', 150, '🛡️', 2),
  ('dai_su_moi_truong', 'Đại sứ Môi trường', 500, '🏅', 3),
  ('bac_thay_phan_loai', 'Bậc thầy Phân loại', 1000, '👑', 4)
ON CONFLICT (code) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Immutable audit log (append-only via trigger)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id bigserial PRIMARY KEY,
  actor_id uuid REFERENCES auth.users (id),
  action text NOT NULL,
  entity_type text,
  entity_id text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs (actor_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- Double authorization for sensitive admin operations
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.privileged_action_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  action_type public.privileged_action_type NOT NULL,
  state public.privileged_action_state NOT NULL DEFAULT 'draft',
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  requester_id uuid NOT NULL REFERENCES auth.users (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  executed_at timestamptz,
  execution_note text
);

CREATE TABLE IF NOT EXISTS public.privileged_action_approvals (
  id bigserial PRIMARY KEY,
  request_id uuid NOT NULL REFERENCES public.privileged_action_requests (id) ON DELETE CASCADE,
  approver_id uuid NOT NULL REFERENCES auth.users (id),
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (request_id, approver_id)
);

CREATE INDEX IF NOT EXISTS idx_par_state ON public.privileged_action_requests (state, created_at DESC);

-- =============================================================================
-- Functions
-- =============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.prevent_audit_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only';
END;
$$;

-- Kill switch + maintenance: super_admin bypass in app logic; RLS uses this
CREATE OR REPLACE FUNCTION public.is_maintenance_mode()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE((value->>'enabled')::boolean, false)
  FROM public.system_settings
  WHERE key = 'maintenance';
$$;

CREATE OR REPLACE FUNCTION public.is_kill_switch_on()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE((value->>'kill_switch')::boolean, false)
  FROM public.system_settings
  WHERE key = 'maintenance';
$$;

-- Role helpers (security definer to avoid RLS recursion on profiles)
CREATE OR REPLACE FUNCTION public.current_profile_role()
RETURNS public.app_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin'
  );
$$;

-- Level from XP (tunable curve)
CREATE OR REPLACE FUNCTION public.xp_to_level(xp bigint)
RETURNS int
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT GREATEST(1, 1 + (xp / 100)::int);
$$;

-- Single source of truth for XP/level: point_ledger rows (insert via Edge Function / RPC with checks).
CREATE OR REPLACE FUNCTION public.apply_xp_to_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid;
BEGIN
  IF TG_OP = 'INSERT' AND TG_TABLE_NAME = 'point_ledger' THEN
    uid := NEW.user_id;
    UPDATE public.profiles p
    SET
      xp_total = GREATEST(0, p.xp_total + NEW.delta),
      level = public.xp_to_level(GREATEST(0, p.xp_total + NEW.delta))
    WHERE p.id = uid;
  END IF;

  RETURN NEW;
END;
$$;

-- Approve submission: promote to dictionary + optional game row (admin RPC)
CREATE OR REPLACE FUNCTION public.admin_approve_waste_submission(
  p_submission_id uuid,
  p_slug text,
  p_merge_existing_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  sub public.waste_submissions%ROWTYPE;
  new_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO sub FROM public.waste_submissions WHERE id = p_submission_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'submission not found';
  END IF;
  IF sub.status <> 'pending_review' THEN
    RAISE EXCEPTION 'invalid status';
  END IF;

  IF p_merge_existing_id IS NOT NULL THEN
    UPDATE public.waste_submissions
    SET
      status = 'merged_existing',
      merged_dictionary_id = p_merge_existing_id,
      reviewer_id = auth.uid(),
      reviewed_at = now(),
      updated_at = now()
    WHERE id = p_submission_id;
    RETURN p_merge_existing_id;
  END IF;

  INSERT INTO public.waste_dictionary (
    slug, name_vi, description, fun_fact, image_url,
    waste_group_id, ai_model_class_id, created_by
  )
  VALUES (
    p_slug,
    COALESCE(sub.suggested_name_vi, 'Chưa đặt tên'),
    NULL,
    sub.suggested_fun_fact,
    sub.suggested_image_url,
    COALESCE(sub.suggested_group_id, (SELECT id FROM public.waste_groups WHERE code = 'trash' LIMIT 1)),
    (SELECT id FROM public.ai_model_classes WHERE label = sub.tflite_top_label LIMIT 1),
    auth.uid()
  )
  RETURNING id INTO new_id;

  INSERT INTO public.game_questions (waste_dictionary_id, game_types, payload)
  VALUES (
    new_id,
    ARRAY['quiz']::text[],
    jsonb_build_object(
      'image_url', sub.suggested_image_url,
      'fun_fact', sub.suggested_fun_fact,
      'source_submission_id', p_submission_id
    )
  );

  UPDATE public.waste_submissions
  SET
    status = 'approved',
    merged_dictionary_id = new_id,
    reviewer_id = auth.uid(),
    reviewed_at = now(),
    updated_at = now()
  WHERE id = p_submission_id;

  RETURN new_id;
END;
$$;

-- GIS: nearest points within radius (meters) — uses GiST index
CREATE OR REPLACE FUNCTION public.collection_points_nearby(
  lat double precision,
  lon double precision,
  radius_m double precision DEFAULT 2000,
  max_rows int DEFAULT 50
)
RETURNS TABLE (
  id uuid,
  name text,
  distance_m double precision,
  lat double precision,
  lon double precision
)
LANGUAGE sql
STABLE
AS $$
  SELECT
    cp.id,
    cp.name,
    ST_Distance(
      cp.location,
      ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography
    ) AS distance_m,
    ST_Y(cp.location::geometry) AS lat,
    ST_X(cp.location::geometry) AS lon
  FROM public.collection_points cp
  WHERE ST_DWithin(
    cp.location,
    ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
    radius_m
  )
  ORDER BY distance_m
  LIMIT max_rows;
$$;

-- Double approval: record vote; transition state when two distinct admins approved
CREATE OR REPLACE FUNCTION public.privileged_action_add_approval(p_request_id uuid, p_comment text DEFAULT NULL)
RETURNS public.privileged_action_state
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  req public.privileged_action_requests%ROWTYPE;
  n int;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT * INTO req FROM public.privileged_action_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'request not found';
  END IF;

  IF req.state NOT IN ('draft', 'awaiting_second_approval') THEN
    RAISE EXCEPTION 'not awaiting approval';
  END IF;

  IF req.requester_id = auth.uid() THEN
    RAISE EXCEPTION 'requester cannot approve own request';
  END IF;

  INSERT INTO public.privileged_action_approvals (request_id, approver_id, comment)
  VALUES (p_request_id, auth.uid(), p_comment)
  ON CONFLICT (request_id, approver_id) DO NOTHING;

  SELECT COUNT(DISTINCT approver_id) INTO n
  FROM public.privileged_action_approvals
  WHERE request_id = p_request_id;

  IF n >= 2 THEN
    UPDATE public.privileged_action_requests
    SET state = 'approved', updated_at = now()
    WHERE id = p_request_id;
    RETURN 'approved';
  END IF;

  UPDATE public.privileged_action_requests
  SET state = 'awaiting_second_approval', updated_at = now()
  WHERE id = p_request_id;

  RETURN 'awaiting_second_approval';
END;
$$;

-- New user → profile row
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name'),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Unlock badges when xp_total crosses thresholds (RLS blocks direct client inserts on user_badges)
CREATE OR REPLACE FUNCTION public.sync_user_badges_from_xp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.xp_total IS DISTINCT FROM OLD.xp_total THEN
    INSERT INTO public.user_badges (user_id, badge_id)
    SELECT NEW.id, b.id
    FROM public.badges b
    WHERE b.threshold_xp IS NOT NULL
      AND NEW.xp_total >= b.threshold_xp
    ON CONFLICT (user_id, badge_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

-- =============================================================================
-- Triggers
-- =============================================================================

DROP TRIGGER IF EXISTS tr_profiles_updated ON public.profiles;
CREATE TRIGGER tr_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_waste_dictionary_updated ON public.waste_dictionary;
CREATE TRIGGER tr_waste_dictionary_updated
  BEFORE UPDATE ON public.waste_dictionary
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_waste_submissions_updated ON public.waste_submissions;
CREATE TRIGGER tr_waste_submissions_updated
  BEFORE UPDATE ON public.waste_submissions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_game_questions_updated ON public.game_questions;
CREATE TRIGGER tr_game_questions_updated
  BEFORE UPDATE ON public.game_questions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_collection_points_updated ON public.collection_points;
CREATE TRIGGER tr_collection_points_updated
  BEFORE UPDATE ON public.collection_points
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_system_settings_updated ON public.system_settings;
CREATE TRIGGER tr_system_settings_updated
  BEFORE UPDATE ON public.system_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_privileged_action_requests_updated ON public.privileged_action_requests;
CREATE TRIGGER tr_privileged_action_requests_updated
  BEFORE UPDATE ON public.privileged_action_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_audit_immutable ON public.audit_logs;
CREATE TRIGGER tr_audit_immutable
  BEFORE UPDATE OR DELETE ON public.audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_audit_mutation();

DROP TRIGGER IF EXISTS tr_point_ledger_xp ON public.point_ledger;
CREATE TRIGGER tr_point_ledger_xp
  AFTER INSERT ON public.point_ledger
  FOR EACH ROW EXECUTE FUNCTION public.apply_xp_to_profile();

DROP TRIGGER IF EXISTS tr_scan_xp ON public.user_scan_events;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS tr_profiles_badges ON public.profiles;
CREATE TRIGGER tr_profiles_badges
  AFTER UPDATE OF xp_total ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.sync_user_badges_from_xp();

-- =============================================================================
-- Row Level Security
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waste_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_model_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waste_dictionary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waste_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_scan_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.privileged_action_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.privileged_action_approvals ENABLE ROW LEVEL SECURITY;

-- Profiles: users read/update self (not role); admin reads all
DROP POLICY IF EXISTS profiles_select_self ON public.profiles;
CREATE POLICY profiles_select_self ON public.profiles
  FOR SELECT USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS profiles_update_self ON public.profiles;
CREATE POLICY profiles_update_self ON public.profiles
  FOR UPDATE
  USING (id = auth.uid() AND NOT public.is_kill_switch_on())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())
  );

DROP POLICY IF EXISTS profiles_admin_update ON public.profiles;
CREATE POLICY profiles_admin_update ON public.profiles
  FOR UPDATE
  USING (public.is_admin() AND NOT public.is_kill_switch_on())
  WITH CHECK (public.is_admin());

-- Read-only reference data
DROP POLICY IF EXISTS waste_groups_read ON public.waste_groups;
CREATE POLICY waste_groups_read ON public.waste_groups FOR SELECT USING (true);

DROP POLICY IF EXISTS ai_classes_read ON public.ai_model_classes;
CREATE POLICY ai_classes_read ON public.ai_model_classes FOR SELECT USING (true);

DROP POLICY IF EXISTS waste_dictionary_read ON public.waste_dictionary;
CREATE POLICY waste_dictionary_read ON public.waste_dictionary
  FOR SELECT USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS waste_dictionary_admin_write ON public.waste_dictionary;
CREATE POLICY waste_dictionary_admin_write ON public.waste_dictionary
  FOR ALL USING (public.is_admin() AND NOT public.is_kill_switch_on())
  WITH CHECK (public.is_admin());

-- Submissions: users insert own; read own; admin all
DROP POLICY IF EXISTS waste_submissions_insert ON public.waste_submissions;
CREATE POLICY waste_submissions_insert ON public.waste_submissions
  FOR INSERT WITH CHECK (
    submitter_id = auth.uid()
    AND NOT public.is_maintenance_mode()
    AND NOT public.is_kill_switch_on()
  );

DROP POLICY IF EXISTS waste_submissions_select ON public.waste_submissions;
CREATE POLICY waste_submissions_select ON public.waste_submissions
  FOR SELECT USING (submitter_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS waste_submissions_admin_update ON public.waste_submissions;
CREATE POLICY waste_submissions_admin_update ON public.waste_submissions
  FOR UPDATE USING (public.is_admin() AND NOT public.is_kill_switch_on());

-- Game questions: public read active; admin write
DROP POLICY IF EXISTS game_questions_read ON public.game_questions;
CREATE POLICY game_questions_read ON public.game_questions
  FOR SELECT USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS game_questions_admin ON public.game_questions;
CREATE POLICY game_questions_admin ON public.game_questions
  FOR ALL USING (public.is_admin() AND NOT public.is_kill_switch_on())
  WITH CHECK (public.is_admin());

-- Collection points: read verified for users; admins see all
DROP POLICY IF EXISTS collection_points_read ON public.collection_points;
CREATE POLICY collection_points_read ON public.collection_points
  FOR SELECT USING (is_verified = true OR public.is_admin());

DROP POLICY IF EXISTS collection_points_admin ON public.collection_points;
CREATE POLICY collection_points_admin ON public.collection_points
  FOR ALL USING (public.is_admin() AND NOT public.is_kill_switch_on())
  WITH CHECK (public.is_admin());

-- Point ledger: own read; insert via service role or trusted RPC only — block direct client insert
DROP POLICY IF EXISTS point_ledger_select_own ON public.point_ledger;
CREATE POLICY point_ledger_select_own ON public.point_ledger
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

-- Scans & game sessions: own rows
DROP POLICY IF EXISTS user_scan_select_insert ON public.user_scan_events;
CREATE POLICY user_scan_select_insert ON public.user_scan_events
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS user_scan_insert ON public.user_scan_events;
CREATE POLICY user_scan_insert ON public.user_scan_events
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND NOT public.is_maintenance_mode()
    AND NOT public.is_kill_switch_on()
  );

DROP POLICY IF EXISTS game_sessions_rw ON public.game_sessions;
CREATE POLICY game_sessions_rw ON public.game_sessions
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS game_sessions_insert ON public.game_sessions;
CREATE POLICY game_sessions_insert ON public.game_sessions
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND NOT public.is_maintenance_mode()
    AND NOT public.is_kill_switch_on()
  );

-- Badges
DROP POLICY IF EXISTS badges_read ON public.badges;
CREATE POLICY badges_read ON public.badges FOR SELECT USING (true);

DROP POLICY IF EXISTS user_badges_read ON public.user_badges;
CREATE POLICY user_badges_read ON public.user_badges
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

-- user_badges: typically updated by server trigger/RPC; deny direct client writes
DROP POLICY IF EXISTS user_badges_no_direct ON public.user_badges;
CREATE POLICY user_badges_no_direct ON public.user_badges
  FOR INSERT WITH CHECK (false);

DROP POLICY IF EXISTS user_badges_no_update ON public.user_badges;
CREATE POLICY user_badges_no_update ON public.user_badges FOR UPDATE USING (false);

-- Audit: admins insert; select admin only
DROP POLICY IF EXISTS audit_insert_admin ON public.audit_logs;
CREATE POLICY audit_insert_admin ON public.audit_logs
  FOR INSERT WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS audit_select_admin ON public.audit_logs;
CREATE POLICY audit_select_admin ON public.audit_logs
  FOR SELECT USING (public.is_admin());

-- Privileged actions
DROP POLICY IF EXISTS par_admin ON public.privileged_action_requests;
CREATE POLICY par_admin ON public.privileged_action_requests
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS paa_admin ON public.privileged_action_approvals;
CREATE POLICY paa_admin ON public.privileged_action_approvals
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- System settings: super_admin only (multi-layer); others no direct write
DROP POLICY IF EXISTS system_settings_read ON public.system_settings;
CREATE POLICY system_settings_read ON public.system_settings
  FOR SELECT USING (true);

-- super_admin can always edit settings (recover from kill_switch / maintenance lockout)
DROP POLICY IF EXISTS system_settings_super_write ON public.system_settings;
CREATE POLICY system_settings_super_write ON public.system_settings
  FOR UPDATE USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());

DROP POLICY IF EXISTS system_settings_super_insert ON public.system_settings;
CREATE POLICY system_settings_super_insert ON public.system_settings
  FOR INSERT WITH CHECK (public.is_super_admin());

-- =============================================================================
-- Grants (authenticated + service_role)
-- =============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO service_role;

GRANT EXECUTE ON FUNCTION public.collection_points_nearby(double precision, double precision, double precision, int) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_approve_waste_submission(uuid, text, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.privileged_action_add_approval(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_maintenance_mode() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_kill_switch_on() TO anon, authenticated;

-- Note: Add SECURITY INVOKER RPCs that insert into point_ledger with auth.uid() checks
-- and call them from Flutter instead of granting INSERT on point_ledger to authenticated.

COMMENT ON TABLE public.waste_dictionary IS 'Official catalog after admin approval; feeds game_questions.';
COMMENT ON TABLE public.waste_submissions IS 'User/Gemini pipeline queue; promote via admin_approve_waste_submission.';
COMMENT ON TABLE public.collection_points IS 'Curated GIS points; geography + GiST for ST_DWithin radius queries.';
COMMENT ON TABLE public.game_sessions IS 'Per-session JSONB detail for Quiz, AR, Sorting without new tables.';
COMMENT ON TABLE public.audit_logs IS 'Append-only audit trail; enforced by trigger.';
COMMENT ON TABLE public.privileged_action_requests IS 'Double-approval workflow for destructive admin actions.';

-- -----------------------------------------------------------------------------
-- Client-safe RPC: award / deduct points (avoids granting INSERT on point_ledger)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_award_points(
  p_delta int,
  p_reason text,
  p_ref_type text DEFAULT NULL,
  p_ref_id uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_xp bigint;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;
  IF public.is_kill_switch_on() THEN
    RAISE EXCEPTION 'service temporarily disabled';
  END IF;
  IF public.is_maintenance_mode() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'maintenance';
  END IF;

  INSERT INTO public.point_ledger (user_id, delta, reason, ref_type, ref_id, metadata)
  VALUES (auth.uid(), p_delta, p_reason, p_ref_type, p_ref_id, COALESCE(p_metadata, '{}'::jsonb));

  SELECT xp_total INTO new_xp FROM public.profiles WHERE id = auth.uid();
  RETURN new_xp;
END;
$$;

GRANT EXECUTE ON FUNCTION public.rpc_award_points(int, text, text, uuid, jsonb) TO authenticated;
