-- Stack Standards Migration: 001_initial_schema
-- Version: 1.0
-- Description: Core tables for Vercel + Supabase full stack application
-- Compatible: PostgreSQL 15+ (Supabase)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- PROFILES TABLE (User data with roles)
-- =====================================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    role TEXT NOT NULL DEFAULT 'candidate' CHECK (role IN ('admin', 'candidate', 'client')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'pending')),
    avatar_url TEXT,
    phone TEXT,
    address JSONB,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for profiles
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX idx_profiles_email ON public.profiles(email) WHERE status = 'active';
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_status ON public.profiles(status);

-- =====================================================
-- SESSIONS TABLE (Unique session management)
-- =====================================================
CREATE TABLE public.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL UNIQUE,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_activity TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sessions_user_id ON public.sessions(user_id);
CREATE INDEX idx_sessions_token ON public.sessions(session_token);
CREATE INDEX idx_sessions_expires ON public.sessions(expires_at);

-- =====================================================
-- PAGE REGISTRY (Role-based page access)
-- =====================================================
CREATE TABLE public.page_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    page_id TEXT NOT NULL UNIQUE,  -- 5-char hex: A1B2C
    path TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    required_role TEXT CHECK (required_role IN ('admin', 'candidate', 'client', 'public')),
    icon TEXT,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default pages
INSERT INTO public.page_registry (page_id, path, title, description, required_role, order_index) VALUES
('A1B2C', '/login', 'Login', 'User authentication', 'public', 0),
('D3E4F', '/signup', 'Sign Up', 'User registration', 'public', 1),
('G5H6I', '/recover', 'Recover', 'Account recovery', 'public', 2),
('M9N0O', '/dashboard', 'Dashboard', 'Main dashboard', 'candidate', 10),
('P1Q2R', '/dashboard/home', 'Home', 'Home page with tasks', 'candidate', 11),
('S3T4U', '/dashboard/classroom', 'Classroom', 'Training and tasks', 'candidate', 12),
('V5W6X', '/dashboard/policies', 'Policies', 'Policies and legal', 'candidate', 13),
('Y7Z8A', '/dashboard/profile', 'Profile', 'User profile', 'candidate', 14),
('B9C0D', '/admin', 'Admin', 'Admin portal', 'admin', 100),
('E1F2G', '/admin/users', 'Users', 'User management', 'admin', 101),
('H3I4J', '/admin/tasks', 'Tasks', 'Task management', 'admin', 102),
('K5L6M', '/admin/contracts', 'Contracts', 'Contract management', 'admin', 103);

-- =====================================================
-- FILE REGISTRY (Track all files)
-- =====================================================
CREATE TABLE public.file_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id TEXT NOT NULL UNIQUE,  -- 5-char hex: A1B2C
    filename TEXT NOT NULL,
    original_name TEXT,
    description TEXT,
    functionality TEXT,
    "connection" TEXT,
    file_type TEXT,
    file_size BIGINT,
    storage_path TEXT,
    bucket_name TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_file_registry_file_id ON public.file_registry(file_id);

-- =====================================================
-- TASKS TABLE (Admin-assigned tasks)
-- =====================================================
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL CHECK (type IN ('upload', 'form', 'video', 'training', 'document')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'submitted', 'approved', 'rejected')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    due_date TIMESTAMPTZ,
    assigned_by UUID REFERENCES auth.users(id),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX idx_tasks_status ON public.tasks(status);
CREATE INDEX idx_tasks_type ON public.tasks(type);
CREATE INDEX idx_tasks_due_date ON public.tasks(due_date);

-- =====================================================
-- TASK SUBMISSIONS (User submissions)
-- =====================================================
CREATE TABLE public.task_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    submission_data JSONB,
    submission_text TEXT,
    file_urls JSONB DEFAULT '[]',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_task_submissions_task_id ON public.task_submissions(task_id);
CREATE INDEX idx_task_submissions_user_id ON public.task_submissions(user_id);

-- =====================================================
-- DOCUMENTATION STAGES (Timer stages)
-- =====================================================
CREATE TABLE public.documentation_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL DEFAULT 0,
    default_duration_days INTEGER DEFAULT 7,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default stages
INSERT INTO public.documentation_stages (name, description, order_index, default_duration_days) VALUES
('Document Validation', 'Initial document review', 1, 3),
('Background Check', 'Background verification', 2, 5),
('Skill Validation', 'Skills assessment', 3, 3),
('Education Validation', 'Education verification', 4, 3),
('Visa Expiration', 'Work authorization check', 5, 2);

-- =====================================================
-- USER DOCUMENTATION (Per-user stage tracking)
-- =====================================================
CREATE TABLE public.user_documentation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    stage_id UUID NOT NULL REFERENCES public.documentation_stages(id),
    status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'skipped')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_doc_user_id ON public.user_documentation(user_id);
CREATE INDEX idx_user_doc_stage ON public.user_documentation(stage_id);

-- =====================================================
-- POLICIES TABLE (Legal/policy content)
-- =====================================================
CREATE TABLE public.policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT,
    category TEXT,
    jurisdiction TEXT,  -- e.g., 'US-FL', 'US-CA', 'federal'
    is_global BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_policies_category ON public.policies(category);
CREATE INDEX idx_policies_jurisdiction ON public.policies(jurisdiction);

-- =====================================================
-- POLICY ACKNOWLEDGMENTS
-- =====================================================
CREATE TABLE public.policy_acknowledgments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    policy_id UUID NOT NULL REFERENCES public.policies(id),
    acknowledged_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET
);

CREATE INDEX idx_policy_ack_user ON public.policy_acknowledgments(user_id);

-- =====================================================
-- CONTRACTS TABLE
-- =====================================================
CREATE TABLE public.contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT,
    file_name TEXT,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'expired', 'terminated')),
    employer_id UUID REFERENCES auth.users(id),
    candidate_id UUID REFERENCES auth.users(id),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_contracts_employer ON public.contracts(employer_id);
CREATE INDEX idx_contracts_candidate ON public.contracts(candidate_id);

-- =====================================================
-- LEGAL REFERENCES (State/federal laws)
-- =====================================================
CREATE TABLE public.legal_references (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    url TEXT,
    jurisdiction TEXT NOT NULL,  -- 'US-FL', 'federal', etc.
    category TEXT,  -- 'immigration', 'labor', 'tax', etc.
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_legal_jurisdiction ON public.legal_references(jurisdiction);
CREATE INDEX idx_legal_category ON public.legal_references(category);

-- =====================================================
-- EMPLOYER REQUESTS (Job postings)
-- =====================================================
CREATE TABLE public.employer_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employer_id UUID NOT NULL REFERENCES auth.users(id),
    title TEXT NOT NULL,
    description TEXT,
    requirements JSONB DEFAULT '[]',
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'filled', 'cancelled')),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TRAININGS (Video/content)
-- =====================================================
CREATE TABLE public.trainings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL CHECK (type IN ('video', 'text', 'document')),
    content_url TEXT,
    content_text TEXT,
    duration_minutes INTEGER,
    is_required BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TRAINING PROGRESS
-- =====================================================
CREATE TABLE public.training_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    training_id UUID NOT NULL REFERENCES public.trainings(id),
    status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    progress_percent INTEGER DEFAULT 0,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_training_progress_user ON public.training_progress(user_id);

-- =====================================================
-- AUDIT LOGS (Security tracking)
-- =====================================================
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX idx_audit_logs_created ON public.audit_logs(created_at);

-- =====================================================
-- SECURITY INCIDENTS
-- =====================================================
CREATE TABLE public.security_incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_type TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    user_id UUID REFERENCES auth.users(id),
    description TEXT,
    ip_address INET,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'escalated')),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- UPDATE FUNCTION (updated_at trigger)
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contracts_updated_at BEFORE UPDATE ON public.contracts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_policies_updated_at BEFORE UPDATE ON public.policies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ENABLE RLS ON ALL TABLES
-- =====================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.page_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.file_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentation_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_documentation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.policy_acknowledgments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_references ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_incidents ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES (Core - to be expanded in next migration)
-- =====================================================

-- Profiles: Users see own, Admins see all
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Sessions: User only
CREATE POLICY "sessions_user_select" ON public.sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "sessions_user_insert" ON public.sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "sessions_user_delete" ON public.sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Tasks: User sees own, Admin sees all
CREATE POLICY "tasks_select_own" ON public.tasks
    FOR SELECT USING (
        auth.uid() = user_id 
        OR EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Page Registry: Public read
CREATE POLICY "page_registry_public_read" ON public.page_registry
    FOR SELECT USING (true);

-- Documentation Stages: Public read
CREATE POLICY "stages_public_read" ON public.documentation_stages
    FOR SELECT USING (true);

-- Trainings: Public read
CREATE POLICY "trainings_public_read" ON public.trainings
    FOR SELECT USING (true);

-- Audit Logs: Admin only
CREATE POLICY "audit_logs_admin_read" ON public.audit_logs
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Security Incidents: Admin only
CREATE POLICY "incidents_admin_all" ON public.security_incidents
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
    );
