-- Stack Standards Migration: 002_rpc_functions
-- Version: 1.0
-- Description: RPC functions for authentication, sessions, RBAC, and utilities
-- Requires: 001_initial_schema.sql

-- =====================================================
-- AUTHENTICATION FUNCTIONS
-- =====================================================

-- Get user role
CREATE OR REPLACE FUNCTION public.get_user_role(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role
  FROM public.profiles
  WHERE user_id = user_uuid;
  
  RETURN COALESCE(user_role, 'candidate');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role
  FROM public.profiles
  WHERE user_id = user_uuid;
  
  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get display name for role
CREATE OR REPLACE FUNCTION public.get_role_display_name(role TEXT)
RETURNS TEXT AS $$
BEGIN
  CASE role
    WHEN 'admin' THEN RETURN 'Admin';
    WHEN 'client' THEN RETURN 'VIP Client';
    WHEN 'candidate' THEN RETURN 'Candidate';
    ELSE RETURN 'User';
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- SESSION MANAGEMENT FUNCTIONS
-- =====================================================

-- Create new session
CREATE OR REPLACE FUNCTION public.create_session(
  p_user_id UUID,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_session_id UUID;
  v_token TEXT;
BEGIN
  -- Generate unique session token
  v_token := encode(gen_random_bytes(32), 'hex');
  
  -- Create session record
  INSERT INTO public.sessions (
    user_id,
    session_token,
    ip_address,
    user_agent,
    expires_at
  ) VALUES (
    p_user_id,
    v_token,
    p_ip_address,
    p_user_agent,
    NOW() + INTERVAL '7 days'
  )
  RETURNING id INTO v_session_id;
  
  RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Validate session
CREATE OR REPLACE FUNCTION public.validate_session(p_session_token TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_session RECORD;
BEGIN
  SELECT * INTO v_session
  FROM public.sessions
  WHERE session_token = p_session_token
    AND expires_at > NOW();
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Update last activity
  UPDATE public.sessions
  SET last_activity = NOW()
  WHERE id = v_session.id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Terminate session
CREATE OR REPLACE FUNCTION public.terminate_session(p_session_token TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  DELETE FROM public.sessions
  WHERE session_token = p_session_token;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Clean expired sessions
CREATE OR REPLACE FUNCTION public.clean_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
  v_deleted INTEGER;
BEGIN
  DELETE FROM public.sessions
  WHERE expires_at < NOW();
  
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROLE-BASED ACCESS CONTROL (RBAC) FUNCTIONS
-- =====================================================

-- Check if user can access page
CREATE OR REPLACE FUNCTION public.can_access_page(
  p_user_id UUID,
  p_page_path TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_role TEXT;
  v_page_role TEXT;
BEGIN
  -- Get user role
  SELECT role INTO v_user_role
  FROM public.profiles
  WHERE user_id = p_user_id;
  
  -- Get required role for page
  SELECT required_role INTO v_page_role
  FROM public.page_registry
  WHERE path = p_page_path
    AND is_active = TRUE;
  
  -- Admin can access everything
  IF v_user_role = 'admin' THEN
    RETURN TRUE;
  END IF;
  
  -- Check role match
  IF v_page_role = 'public' THEN
    RETURN TRUE;
  END IF;
  
  IF v_user_role = v_page_role THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Check if user can view another user's data
CREATE OR REPLACE FUNCTION public.can_view_user_data(
  p_viewer_id UUID,
  p_target_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_viewer_role TEXT;
  v_target_role TEXT;
BEGIN
  -- Get viewer role
  SELECT role INTO v_viewer_role
  FROM public.profiles
  WHERE user_id = p_viewer_id;
  
  -- Get target role
  SELECT role INTO v_target_role
  FROM public.profiles
  WHERE user_id = p_target_id;
  
  -- Admin can view all
  IF v_viewer_role = 'admin' THEN
    RETURN TRUE;
  END IF;
  
  -- Same user can view own data
  IF p_viewer_id = p_target_id THEN
    RETURN TRUE;
  END IF;
  
  -- Employers can see assigned candidates (non-PII)
  IF v_viewer_role = 'client' AND v_target_role = 'candidate' THEN
    -- Return true for non-sensitive data
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TASK MANAGEMENT FUNCTIONS
-- =====================================================

-- Get tasks for user with details
CREATE OR REPLACE FUNCTION public.get_user_tasks(
  p_user_id UUID,
  p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  type TEXT,
  status TEXT,
  priority TEXT,
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.title,
    t.description,
    t.type,
    t.status,
    t.priority,
    t.due_date,
    t.created_at
  FROM public.tasks t
  WHERE t.user_id = p_user_id
    AND (p_status IS NULL OR t.status = p_status)
  ORDER BY 
    CASE t.priority
      WHEN 'urgent' THEN 1
      WHEN 'high' THEN 2
      WHEN 'normal' THEN 3
      WHEN 'low' THEN 4
    END,
    t.due_date ASC NULLS LAST,
    t.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Create task
CREATE OR REPLACE FUNCTION public.create_task(
  p_user_id UUID,
  p_title TEXT,
  p_description TEXT DEFAULT NULL,
  p_type TEXT,
  p_priority TEXT DEFAULT 'normal',
  p_due_date TIMESTAMPTZ DEFAULT NULL,
  p_assigned_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_task_id UUID;
BEGIN
  INSERT INTO public.tasks (
    user_id,
    title,
    description,
    type,
    priority,
    due_date,
    assigned_by,
    status
  ) VALUES (
    p_user_id,
    p_title,
    p_description,
    p_type,
    p_priority,
    p_due_date,
    p_assigned_by,
    'pending'
  )
  RETURNING id INTO v_task_id;
  
  RETURN v_task_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Submit task
CREATE OR REPLACE FUNCTION public.submit_task(
  p_task_id UUID,
  p_submission_data JSONB DEFAULT '{}',
  p_submission_text TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_task_id UUID;
BEGIN
  -- Update task status
  UPDATE public.tasks
  SET status = 'submitted', updated_at = NOW()
  WHERE id = p_task_id;
  
  -- Create submission record
  INSERT INTO public.task_submissions (
    task_id,
    user_id,
    submission_data,
    submission_text,
    status
  ) VALUES (
    p_task_id,
    (SELECT user_id FROM public.tasks WHERE id = p_task_id),
    p_submission_data,
    p_submission_text,
    'pending'
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Approve/reject task
CREATE OR REPLACE FUNCTION public.review_task(
  p_submission_id UUID,
  p_status TEXT,
  p_rejection_reason TEXT DEFAULT NULL,
  p_reviewer_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_task_id UUID;
  v_user_id UUID;
BEGIN
  -- Get submission details
  SELECT task_id, user_id INTO v_task_id, v_user_id
  FROM public.task_submissions
  WHERE id = p_submission_id;
  
  -- Update submission
  UPDATE public.task_submissions
  SET status = p_status,
      rejection_reason = p_rejection_reason,
      reviewed_by = p_reviewer_id,
      reviewed_at = NOW()
  WHERE id = p_submission_id;
  
  -- Update task status
  UPDATE public.tasks
  SET status = p_status, updated_at = NOW()
  WHERE id = v_task_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DOCUMENTATION STAGE FUNCTIONS
-- =====================================================

-- Get user's current documentation stage
CREATE OR REPLACE FUNCTION public.get_current_stage(p_user_id UUID)
RETURNS TABLE (
  stage_id UUID,
  stage_name TEXT,
  stage_description TEXT,
  order_index INTEGER,
  status TEXT,
  started_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ds.id,
    ds.name,
    ds.description,
    ds.order_index,
    ud.status,
    ud.started_at
  FROM public.user_documentation ud
  JOIN public.documentation_stages ds ON ds.id = ud.stage_id
  WHERE ud.user_id = p_user_id
    AND ud.status = 'in_progress'
  ORDER BY ds.order_index ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Move to next stage
CREATE OR REPLACE FUNCTION public.advance_stage(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_stage RECORD;
  v_next_stage RECORD;
BEGIN
  -- Get current stage
  SELECT * INTO v_current_stage
  FROM public.get_current_stage(p_user_id);
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Get next stage
  SELECT * INTO v_next_stage
  FROM public.documentation_stages
  WHERE order_index > v_current_stage.order_index
    AND is_active = TRUE
  ORDER BY order_index ASC
  LIMIT 1;
  
  IF NOT FOUND THEN
    -- Complete current stage
    UPDATE public.user_documentation
    SET status = 'completed', completed_at = NOW()
    WHERE user_id = p_user_id AND stage_id = v_current_stage.stage_id;
    RETURN TRUE;
  END IF;
  
  -- Complete current stage
  UPDATE public.user_documentation
  SET status = 'completed', completed_at = NOW()
  WHERE user_id = p_user_id AND stage_id = v_current_stage.stage_id;
  
  -- Start next stage
  INSERT INTO public.user_documentation (user_id, stage_id, status)
  VALUES (p_user_id, v_next_stage.id, 'in_progress');
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRAINING FUNCTIONS
-- =====================================================

-- Get training progress
CREATE OR REPLACE FUNCTION public.get_training_progress(p_user_id UUID)
RETURNS TABLE (
  training_id UUID,
  title TEXT,
  type TEXT,
  status TEXT,
  progress_percent INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.title,
    t.type,
    tp.status,
    COALESCE(tp.progress_percent, 0)
  FROM public.trainings t
  LEFT JOIN public.training_progress tp ON tp.training_id = t.id AND tp.user_id = p_user_id
  ORDER BY tp.created_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Update training progress
CREATE OR REPLACE FUNCTION public.update_training_progress(
  p_training_id UUID,
  p_user_id UUID,
  p_progress_percent INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
  v_current RECORD;
  v_status TEXT;
BEGIN
  -- Determine status
  IF p_progress_percent >= 100 THEN
    v_status := 'completed';
  ELSIF p_progress_percent > 0 THEN
    v_status := 'in_progress';
  ELSE
    v_status := 'not_started';
  END IF;
  
  -- Upsert progress
  INSERT INTO public.training_progress (user_id, training_id, progress_percent, status, completed_at)
  VALUES (p_user_id, p_training_id, p_progress_percent, v_status, 
          CASE WHEN v_status = 'completed' THEN NOW() ELSE NULL END)
  ON CONFLICT (user_id, training_id)
  DO UPDATE SET
    progress_percent = p_progress_percent,
    status = v_status,
    completed_at = CASE WHEN v_status = 'completed' THEN NOW() ELSE NULL END;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- AUDIT LOGGING FUNCTIONS
-- =====================================================

-- Create audit log entry
CREATE OR REPLACE FUNCTION public.create_audit_log(
  p_user_id UUID DEFAULT NULL,
  p_action TEXT,
  p_table_name TEXT DEFAULT NULL,
  p_record_id UUID DEFAULT NULL,
  p_old_values JSONB DEFAULT NULL,
  p_new_values JSONB DEFAULT NULL,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.audit_logs (
    user_id,
    action,
    table_name,
    record_id,
    old_values,
    new_values,
    ip_address,
    user_agent
  ) VALUES (
    p_user_id,
    p_action,
    p_table_name,
    p_record_id,
    p_old_values,
    p_new_values,
    p_ip_address,
    p_user_agent
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Generate file ID
CREATE OR REPLACE FUNCTION public.generate_file_id()
RETURNS TEXT AS $$
DECLARE
  v_id TEXT;
  v_exists BOOLEAN := TRUE;
BEGIN
  WHILE v_exists LOOP
    v_id := upper(substring(md5(random()::text) FROM 1 FOR 5));
    SELECT NOT EXISTS(SELECT 1 FROM public.file_registry WHERE file_id = v_id) INTO v_exists;
  END LOOP;
  
  RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Get pages for role
CREATE OR REPLACE FUNCTION public.get_pages_for_role(p_role TEXT)
RETURNS TABLE (
  page_id TEXT,
  path TEXT,
  title TEXT,
  description TEXT,
  icon TEXT,
  order_index INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pr.page_id,
    pr.path,
    pr.title,
    pr.description,
    pr.icon,
    pr.order_index
  FROM public.page_registry pr
  WHERE pr.is_active = TRUE
    AND (pr.required_role = 'public' OR pr.required_role = p_role OR p_role = 'admin')
  ORDER BY pr.order_index;
END;
$$ LANGUAGE plpgsql;

-- Count records by status
CREATE OR REPLACE FUNCTION public.count_by_status(
  p_table_name TEXT,
  p_status_column TEXT,
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (status TEXT, count BIGINT) AS $$
BEGIN
  RETURN QUERY EXECUTE format(
    'SELECT %I, COUNT(*)::BIGINT FROM %I WHERE %s = %L GROUP BY %I',
    p_status_column,
    p_table_name,
    'user_id',
    p_user_id,
    p_status_column
  );
END;
$$ LANGUAGE plpgsql;
