-- ==========================================
-- FRESH START SCHEMA
-- Run this if you want to wipe all data and start completely fresh.
-- ==========================================

-- 1. DROP EXISTING SCHEMA
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- USERS / PROFILES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  business_name TEXT,
  email TEXT,
  avatar_url TEXT,
  theme_id TEXT DEFAULT 'darkProfessional',
  theme_mode TEXT DEFAULT 'dark',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ==========================================
-- WORKSPACES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.workspaces (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.workspace_members (
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'editor', 'viewer')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (workspace_id, user_id)
);

ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can view workspaces" ON public.workspaces 
FOR SELECT USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = id AND user_id = auth.uid()));
CREATE POLICY "Authenticated can create workspaces" ON public.workspaces FOR INSERT WITH CHECK (auth.role() = 'authenticated');

ALTER TABLE public.workspace_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can view members" ON public.workspace_members 
FOR SELECT USING (EXISTS (SELECT 1 FROM public.workspace_members wm WHERE wm.workspace_id = workspace_id AND wm.user_id = auth.uid()));
CREATE POLICY "Authenticated can join workspace" ON public.workspace_members FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ==========================================
-- TASKS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'Medium',
  due_date TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT FALSE,
  is_pinned BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.tasks FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = tasks.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- CONTENT
-- ==========================================
CREATE TABLE IF NOT EXISTS public.content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  stage TEXT DEFAULT 'Raw Thought',
  tags TEXT[] DEFAULT '{}',
  category TEXT,
  format TEXT,
  platform TEXT,
  priority TEXT DEFAULT 'Medium',
  due_date TIMESTAMPTZ,
  notes TEXT,
  attachment_urls TEXT[] DEFAULT '{}',
  related_content_ids UUID[] DEFAULT '{}',
  version INTEGER DEFAULT 1,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.content FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = content.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- LEADS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  company TEXT,
  email TEXT,
  phone TEXT,
  lead_source TEXT,
  industry TEXT,
  deal_value NUMERIC(12, 2) DEFAULT 0,
  stage TEXT DEFAULT 'New',
  notes TEXT,
  follow_up_date TIMESTAMPTZ,
  meeting_history TEXT[] DEFAULT '{}',
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.leads FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = leads.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- CLIENTS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  business_name TEXT,
  email TEXT,
  phone TEXT,
  website TEXT,
  address TEXT,
  gst_number TEXT,
  social_links TEXT[] DEFAULT '{}',
  is_retainer BOOLEAN DEFAULT FALSE,
  retainer_amount NUMERIC(12, 2) DEFAULT 0,
  project_value NUMERIC(12, 2) DEFAULT 0,
  amount_received NUMERIC(12, 2) DEFAULT 0,
  deliverables TEXT[] DEFAULT '{}',
  deadline TIMESTAMPTZ,
  status TEXT DEFAULT 'Active',
  logo_url TEXT,
  brand_colors TEXT[] DEFAULT '{}',
  brand_guidelines TEXT,
  drive_links TEXT[] DEFAULT '{}',
  social_media_access TEXT,
  meeting_notes TEXT,
  internal_notes TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.clients FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = clients.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- TRANSACTIONS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL,
  category TEXT NOT NULL,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  client_name TEXT,
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  description TEXT,
  receipt_url TEXT,
  resource_name TEXT,
  resource_type TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.transactions FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = transactions.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- INVOICES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  client_name TEXT,
  service_name TEXT,
  duration TEXT,
  base_amount NUMERIC(12, 2) DEFAULT 0,
  gst_rate NUMERIC(5, 2) DEFAULT 0,
  tax_amount NUMERIC(12, 2) DEFAULT 0,
  total_amount NUMERIC(12, 2) DEFAULT 0,
  payment_type TEXT,
  amount_paid_previously NUMERIC(12, 2) DEFAULT 0,
  issue_date TIMESTAMPTZ NOT NULL,
  due_date TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'Unpaid',
  pdf_file_path TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.invoices FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = invoices.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- KNOWLEDGE
-- ==========================================
CREATE TABLE IF NOT EXISTS public.knowledge (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL,
  collection_name TEXT,
  tags TEXT[] DEFAULT '{}',
  is_favorite BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.knowledge ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.knowledge FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = knowledge.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- MEETINGS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.meetings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  agenda TEXT,
  participants TEXT[] DEFAULT '{}',
  notes TEXT,
  action_items TEXT[] DEFAULT '{}',
  date TIMESTAMPTZ NOT NULL,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  client_name TEXT,
  requirements TEXT,
  decisions TEXT,
  follow_ups TEXT[] DEFAULT '{}',
  attachment_urls TEXT[] DEFAULT '{}',
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.meetings FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = meetings.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- JOURNAL ENTRIES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  went_well TEXT,
  did_not_go_well TEXT,
  lessons_learned TEXT,
  wins TEXT,
  mistakes TEXT,
  gratitude TEXT,
  improvements_for_tomorrow TEXT,
  mood TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.journal_entries FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = journal_entries.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- FOCUS SESSIONS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.focus_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  task_id UUID,
  task_title TEXT,
  session_type TEXT,
  duration_minutes INTEGER NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  type TEXT,
  completed BOOLEAN DEFAULT FALSE,
  label TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.focus_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.focus_sessions FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = focus_sessions.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- RESOURCES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  cost NUMERIC(10, 2) DEFAULT 0,
  description TEXT,
  is_purchased BOOLEAN DEFAULT TRUE,
  renewal_date TIMESTAMPTZ,
  license_key TEXT,
  url TEXT,
  estimated_cost NUMERIC(10, 2) DEFAULT 0,
  priority TEXT DEFAULT 'Medium',
  purchase_reason TEXT,
  target_purchase_date TIMESTAMPTZ,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Workspace members access" ON public.resources FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = resources.workspace_id AND user_id = auth.uid()));

-- ==========================================
-- TRIGGERS & FUNCTIONS
-- ==========================================

-- Auto-update updated_at on row modification
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['tasks', 'content', 'leads', 'clients', 'transactions', 'knowledge', 'meetings', 'journal_entries', 'focus_sessions', 'resources', 'invoices', 'workspaces', 'profiles']
  LOOP
    EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON public.%s FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', t, t);
  END LOOP;
END;
$$;

-- Auto-create profile and Personal Workspace on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  ws_id UUID;
BEGIN
  -- Insert profile
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.email);

  -- Generate workspace ID
  ws_id := uuid_generate_v4();

  -- Create Personal Workspace
  INSERT INTO public.workspaces (id, name, code)
  VALUES (ws_id, COALESCE(NEW.raw_user_meta_data->>'full_name', 'Personal') || '''s Workspace', right(ws_id::text, 6));

  -- Add user as owner
  INSERT INTO public.workspace_members (workspace_id, user_id, role)
  VALUES (ws_id, NEW.id, 'owner');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
