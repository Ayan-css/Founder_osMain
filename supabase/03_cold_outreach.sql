-- ==========================================
-- Migration: Add cold_outreach table
-- Run this in your Supabase SQL Editor
-- ==========================================

CREATE TABLE IF NOT EXISTS public.cold_outreach (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name          TEXT NOT NULL,
  company       TEXT,
  platform      TEXT NOT NULL DEFAULT 'Other',
  status        TEXT NOT NULL DEFAULT 'Not Replied',
  notes         TEXT,
  follow_up_date TIMESTAMPTZ,
  sync_status   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  workspace_id  UUID REFERENCES public.workspaces(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS cold_outreach_workspace_idx ON public.cold_outreach(workspace_id);
CREATE INDEX IF NOT EXISTS cold_outreach_user_idx      ON public.cold_outreach(user_id);
CREATE INDEX IF NOT EXISTS cold_outreach_created_at_idx ON public.cold_outreach(created_at DESC);

-- Row Level Security
ALTER TABLE public.cold_outreach ENABLE ROW LEVEL SECURITY;

-- Policy: workspace members can SELECT their workspace's outreach entries
CREATE POLICY "Workspace members can view cold_outreach"
  ON public.cold_outreach FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

-- Policy: workspace members can INSERT
CREATE POLICY "Workspace members can insert cold_outreach"
  ON public.cold_outreach FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

-- Policy: workspace members can UPDATE
CREATE POLICY "Workspace members can update cold_outreach"
  ON public.cold_outreach FOR UPDATE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

-- Policy: workspace members can DELETE
CREATE POLICY "Workspace members can delete cold_outreach"
  ON public.cold_outreach FOR DELETE
  USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );
