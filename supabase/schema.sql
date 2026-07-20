-- ==========================================
-- Right Craft Media OS - Supabase Database Schema
-- Complete Schema with RLS, Indexes, and Relationships
-- ==========================================

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
-- TASKS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'Medium' CHECK (priority IN ('Critical', 'High', 'Medium', 'Low')),
  due_date TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT FALSE,
  is_pinned BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX idx_tasks_is_completed ON public.tasks(is_completed);
CREATE INDEX idx_tasks_is_pinned ON public.tasks(is_pinned);
CREATE INDEX idx_tasks_due_date ON public.tasks(due_date);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own tasks" ON public.tasks FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- CONTENT
-- ==========================================
CREATE TABLE IF NOT EXISTS public.content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  stage TEXT DEFAULT 'Raw Thought',
  tags TEXT[] DEFAULT '{}',
  category TEXT,
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

CREATE INDEX idx_content_user_id ON public.content(user_id);
CREATE INDEX idx_content_stage ON public.content(stage);
CREATE INDEX idx_content_platform ON public.content(platform);
CREATE INDEX idx_content_due_date ON public.content(due_date);

ALTER TABLE public.content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own content" ON public.content FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- LEADS (CRM)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  company TEXT,
  email TEXT,
  phone TEXT,
  lead_source TEXT,
  industry TEXT,
  deal_value NUMERIC(12, 2) DEFAULT 0,
  stage TEXT DEFAULT 'New Lead',
  notes TEXT,
  follow_up_date TIMESTAMPTZ,
  meeting_history TEXT[] DEFAULT '{}',
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_leads_user_id ON public.leads(user_id);
CREATE INDEX idx_leads_stage ON public.leads(stage);
CREATE INDEX idx_leads_follow_up_date ON public.leads(follow_up_date);

ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own leads" ON public.leads FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- CLIENTS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  business_name TEXT,
  email TEXT,
  phone TEXT,
  website TEXT,
  social_links TEXT[] DEFAULT '{}',
  project_value NUMERIC(12, 2) DEFAULT 0,
  amount_received NUMERIC(12, 2) DEFAULT 0,
  deliverables TEXT[] DEFAULT '{}',
  deadline TIMESTAMPTZ,
  status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Completed', 'On Hold', 'Cancelled')),
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

CREATE INDEX idx_clients_user_id ON public.clients(user_id);
CREATE INDEX idx_clients_status ON public.clients(status);

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own clients" ON public.clients FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- TRANSACTIONS (Finance)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('revenue', 'expense')),
  amount NUMERIC(12, 2) NOT NULL,
  category TEXT NOT NULL,
  client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
  client_name TEXT,
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  description TEXT,
  receipt_url TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX idx_transactions_type ON public.transactions(type);
CREATE INDEX idx_transactions_date ON public.transactions(date);
CREATE INDEX idx_transactions_category ON public.transactions(category);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own transactions" ON public.transactions FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- KNOWLEDGE
-- ==========================================
CREATE TABLE IF NOT EXISTS public.knowledge (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
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

CREATE INDEX idx_knowledge_user_id ON public.knowledge(user_id);
CREATE INDEX idx_knowledge_category ON public.knowledge(category);
CREATE INDEX idx_knowledge_is_favorite ON public.knowledge(is_favorite);

ALTER TABLE public.knowledge ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own knowledge" ON public.knowledge FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- MEETINGS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.meetings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('internal', 'client')),
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

CREATE INDEX idx_meetings_user_id ON public.meetings(user_id);
CREATE INDEX idx_meetings_date ON public.meetings(date);
CREATE INDEX idx_meetings_type ON public.meetings(type);

ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own meetings" ON public.meetings FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- JOURNAL ENTRIES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  went_well TEXT,
  did_not_go_well TEXT,
  lessons_learned TEXT,
  wins TEXT,
  mistakes TEXT,
  gratitude TEXT,
  improvements_for_tomorrow TEXT,
  mood INTEGER DEFAULT 3 CHECK (mood BETWEEN 1 AND 5),
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_journal_user_id ON public.journal_entries(user_id);
CREATE INDEX idx_journal_date ON public.journal_entries(date);

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own journal" ON public.journal_entries FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- FOCUS SESSIONS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.focus_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  completed BOOLEAN DEFAULT FALSE,
  label TEXT,
  sync_status TEXT DEFAULT 'synced',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_focus_user_id ON public.focus_sessions(user_id);
CREATE INDEX idx_focus_start_time ON public.focus_sessions(start_time);
CREATE INDEX idx_focus_completed ON public.focus_sessions(completed);

ALTER TABLE public.focus_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own sessions" ON public.focus_sessions FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- RESOURCES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
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

CREATE INDEX idx_resources_user_id ON public.resources(user_id);
CREATE INDEX idx_resources_is_purchased ON public.resources(is_purchased);
CREATE INDEX idx_resources_renewal_date ON public.resources(renewal_date);

ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own resources" ON public.resources FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- ACTIVITY LOG
-- ==========================================
CREATE TABLE IF NOT EXISTS public.activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_user_id ON public.activity_log(user_id);
CREATE INDEX idx_activity_created_at ON public.activity_log(created_at);

ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own activity" ON public.activity_log FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own activity" ON public.activity_log FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ==========================================
-- FUNCTIONS
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
  FOREACH t IN ARRAY ARRAY['tasks', 'content', 'leads', 'clients', 'transactions', 'knowledge', 'meetings', 'journal_entries', 'focus_sessions', 'resources', 'profiles']
  LOOP
    EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON public.%s FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', t, t);
  END LOOP;
END;
$$;

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ==========================================
-- STORAGE BUCKETS
-- ==========================================
-- Run in Supabase Dashboard > Storage:
-- 1. Create bucket: 'attachments' (public: false)
-- 2. Create bucket: 'brand-assets' (public: false)
-- 3. Create bucket: 'receipts' (public: false)

-- Storage RLS policies (run after creating buckets):
-- CREATE POLICY "Users can upload own files" ON storage.objects FOR INSERT WITH CHECK (auth.uid()::text = (storage.foldername(name))[1]);
-- CREATE POLICY "Users can view own files" ON storage.objects FOR SELECT USING (auth.uid()::text = (storage.foldername(name))[1]);
-- CREATE POLICY "Users can delete own files" ON storage.objects FOR DELETE USING (auth.uid()::text = (storage.foldername(name))[1]);
