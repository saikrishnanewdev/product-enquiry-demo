-- ============================================================
-- Product Enquiry Demo — Supabase setup
-- Run this whole file in your Supabase dashboard:
--   Supabase Dashboard -> SQL Editor -> New query -> paste -> Run
-- (Same pattern Sai already uses for the Karthikeya site.)
-- ============================================================

-- 1. Tables ----------------------------------------------------
create table if not exists public.enquiries (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  mobile text not null,
  description text not null,
  photo_url text,
  status text not null default 'new',
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  enquiry_id uuid not null references public.enquiries(id) on delete cascade,
  sender text not null check (sender in ('customer', 'owner')),
  message text not null,
  created_at timestamptz not null default now()
);

create index if not exists messages_enquiry_id_idx
  on public.messages (enquiry_id, created_at);

-- 2. Realtime (so the owner sees new enquiries + chat instantly) --
alter publication supabase_realtime add table public.enquiries;
alter publication supabase_realtime add table public.messages;

-- 3. Storage bucket for product photos -------------------------
insert into storage.buckets (id, name, public)
values ('enquiry-photos', 'enquiry-photos', true)
on conflict (id) do nothing;

-- 4. Open policies for the DEMO --------------------------------
-- (Demo only: anyone with the anon key can read/write. For the real
--  app later, replace these with proper per-user rules.)
alter table public.enquiries enable row level security;
alter table public.messages enable row level security;

drop policy if exists "Demo: anyone can read enquiries" on public.enquiries;
create policy "Demo: anyone can read enquiries"
  on public.enquiries for select using (true);

drop policy if exists "Demo: anyone can add enquiries" on public.enquiries;
create policy "Demo: anyone can add enquiries"
  on public.enquiries for insert with check (true);

drop policy if exists "Demo: anyone can update enquiries" on public.enquiries;
create policy "Demo: anyone can update enquiries"
  on public.enquiries for update using (true);

drop policy if exists "Demo: anyone can read messages" on public.messages;
create policy "Demo: anyone can read messages"
  on public.messages for select using (true);

drop policy if exists "Demo: anyone can send messages" on public.messages;
create policy "Demo: anyone can send messages"
  on public.messages for insert with check (true);

drop policy if exists "Demo: anyone can upload photos" on storage.objects;
create policy "Demo: anyone can upload photos"
  on storage.objects for insert with check (bucket_id = 'enquiry-photos');

drop policy if exists "Demo: anyone can view photos" on storage.objects;
create policy "Demo: anyone can view photos"
  on storage.objects for select using (bucket_id = 'enquiry-photos');

-- 5. Device tokens for push notifications (FCM) ----------------
-- Each phone saves its FCM token here so the Edge Function
-- (supabase/functions/send-push) knows where to send the push.
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  role text not null check (role in ('owner', 'customer')),
  enquiry_id uuid references public.enquiries(id) on delete cascade,
  token text not null unique,
  created_at timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

drop policy if exists "Demo: anyone can read device tokens" on public.device_tokens;
create policy "Demo: anyone can read device tokens"
  on public.device_tokens for select using (true);

drop policy if exists "Demo: anyone can save device tokens" on public.device_tokens;
create policy "Demo: anyone can save device tokens"
  on public.device_tokens for insert with check (true);

drop policy if exists "Demo: anyone can update device tokens" on public.device_tokens;
create policy "Demo: anyone can update device tokens"
  on public.device_tokens for update using (true);
