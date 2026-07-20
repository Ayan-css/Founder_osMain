-- ==========================================
-- MIGRATION SCRIPT (KEEP EXISTING DATA)
-- Run this if you want to keep your existing data but upgrade to Team Workspaces.
-- ==========================================

-- 1. CREATE NEW TABLES
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

CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE,
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

-- 2. ADD workspace_id TO EXISTING TABLES
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.content ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.leads ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.clients ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.knowledge ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.focus_sessions ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;
ALTER TABLE public.resources ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE;

-- 3. MIGRATION DATA BLOCK
-- Give everyone a Personal Workspace and migrate their old data to it
DO $$
DECLARE
    u_row RECORD;
    ws_id UUID;
BEGIN
    FOR u_row IN SELECT id, full_name FROM public.profiles LOOP
        -- Generate random 6 char code
        ws_id := uuid_generate_v4();
        
        -- Insert a Personal Workspace
        INSERT INTO public.workspaces (id, name, code) 
        VALUES (ws_id, COALESCE(u_row.full_name, 'Personal') || '''s Workspace', right(ws_id::text, 6))
        ON CONFLICT DO NOTHING;
        
        -- Make them the owner
        INSERT INTO public.workspace_members (workspace_id, user_id, role)
        VALUES (ws_id, u_row.id, 'owner')
        ON CONFLICT DO NOTHING;
        
        -- Migrate data to this new workspace
        UPDATE public.tasks SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.content SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.leads SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.clients SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.transactions SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.knowledge SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.meetings SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.journal_entries SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.focus_sessions SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
        UPDATE public.resources SET workspace_id = ws_id WHERE user_id = u_row.id AND workspace_id IS NULL;
    END LOOP;
END $$;

-- 4. SET workspace_id NOT NULL
-- (Only run this if you are absolutely sure all old data is successfully migrated above!)
-- If it fails, run: DELETE FROM <table_name> WHERE workspace_id IS NULL;
ALTER TABLE public.tasks ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.content ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.leads ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.clients ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.transactions ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.knowledge ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.meetings ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.journal_entries ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.focus_sessions ALTER COLUMN workspace_id SET NOT NULL;
ALTER TABLE public.resources ALTER COLUMN workspace_id SET NOT NULL;

-- 5. UPDATE RLS POLICIES 
-- Drop old user_id policies
DROP POLICY IF EXISTS "Users can CRUD own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can CRUD own content" ON public.content;
DROP POLICY IF EXISTS "Users can CRUD own leads" ON public.leads;
DROP POLICY IF EXISTS "Users can CRUD own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can CRUD own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can CRUD own knowledge" ON public.knowledge;
DROP POLICY IF EXISTS "Users can CRUD own meetings" ON public.meetings;
DROP POLICY IF EXISTS "Users can CRUD own journal" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can CRUD own sessions" ON public.focus_sessions;
DROP POLICY IF EXISTS "Users can CRUD own resources" ON public.resources;

-- Enable RLS
ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- Workspace Policies
CREATE POLICY "Members can view workspaces" ON public.workspaces 
FOR SELECT USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = id AND user_id = auth.uid()));
CREATE POLICY "Authenticated can create workspaces" ON public.workspaces FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Members can view members" ON public.workspace_members 
FOR SELECT USING (EXISTS (SELECT 1 FROM public.workspace_members wm WHERE wm.workspace_id = workspace_id AND wm.user_id = auth.uid()));
CREATE POLICY "Authenticated can join workspace" ON public.workspace_members FOR INSERT WITH CHECK (auth.uid() = user_id);

-- New Role-Based Policies
CREATE POLICY "Workspace members access tasks" ON public.tasks FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = tasks.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access content" ON public.content FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = content.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access leads" ON public.leads FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = leads.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access clients" ON public.clients FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = clients.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access transactions" ON public.transactions FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = transactions.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access knowledge" ON public.knowledge FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = knowledge.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access meetings" ON public.meetings FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = meetings.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access journal_entries" ON public.journal_entries FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = journal_entries.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access focus_sessions" ON public.focus_sessions FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = focus_sessions.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access resources" ON public.resources FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = resources.workspace_id AND user_id = auth.uid()));
CREATE POLICY "Workspace members access invoices" ON public.invoices FOR ALL USING (EXISTS (SELECT 1 FROM public.workspace_members WHERE workspace_id = invoices.workspace_id AND user_id = auth.uid()));

-- Update auth trigger to also create a personal workspace
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
