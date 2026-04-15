-- ==========================================
-- FlexiCost SaaS — Supabase Migration
-- Supabase Dashboard → SQL Editor'de çalıştırın
-- ==========================================

-- 1. Profiles (auth.users ile birlikte otomatik oluşur)
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  company_name text default '',
  email text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
create policy "profiles_select" on public.profiles for select using (auth.uid() = id);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id);
create policy "profiles_insert" on public.profiles for insert with check (auth.uid() = id);

-- Kayıt olunca otomatik profil oluştur
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 2. Makine Fiyatları (kullanıcı başına tek kayıt)
create table if not exists public.machine_rates (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null unique,
  data jsonb not null default '{}',
  updated_at timestamptz default now()
);

alter table public.machine_rates enable row level security;
create policy "machine_rates_select" on public.machine_rates for select using (auth.uid() = user_id);
create policy "machine_rates_insert" on public.machine_rates for insert with check (auth.uid() = user_id);
create policy "machine_rates_update" on public.machine_rates for update using (auth.uid() = user_id);
create policy "machine_rates_delete" on public.machine_rates for delete using (auth.uid() = user_id);

-- 3. Fiyat Profilleri
create table if not exists public.rate_profiles (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  data jsonb not null default '{}',
  created_at timestamptz default now()
);

alter table public.rate_profiles enable row level security;
create policy "rate_profiles_select" on public.rate_profiles for select using (auth.uid() = user_id);
create policy "rate_profiles_insert" on public.rate_profiles for insert with check (auth.uid() = user_id);
create policy "rate_profiles_update" on public.rate_profiles for update using (auth.uid() = user_id);
create policy "rate_profiles_delete" on public.rate_profiles for delete using (auth.uid() = user_id);

-- 4. Müşteriler
create table if not exists public.clients (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  contact text default '',
  phone text default '',
  email text default '',
  addr text default '',
  city text default '',
  country text default 'Türkiye',
  vd text default '',
  vno text default '',
  notes text default '',
  created_at timestamptz default now()
);

alter table public.clients enable row level security;
create policy "clients_select" on public.clients for select using (auth.uid() = user_id);
create policy "clients_insert" on public.clients for insert with check (auth.uid() = user_id);
create policy "clients_update" on public.clients for update using (auth.uid() = user_id);
create policy "clients_delete" on public.clients for delete using (auth.uid() = user_id);

-- 5. Ürün Şablonları
create table if not exists public.templates (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  snapshot jsonb not null default '{}',
  created_at timestamptz default now()
);

alter table public.templates enable row level security;
create policy "templates_select" on public.templates for select using (auth.uid() = user_id);
create policy "templates_insert" on public.templates for insert with check (auth.uid() = user_id);
create policy "templates_update" on public.templates for update using (auth.uid() = user_id);
create policy "templates_delete" on public.templates for delete using (auth.uid() = user_id);

-- 6. Hesaplama Geçmişi
create table if not exists public.calculations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  pkg text,
  size text,
  qty text,
  total text,
  eur_kg text,
  layer_str text,
  snapshot jsonb,
  created_at timestamptz default now()
);

alter table public.calculations enable row level security;
create policy "calculations_select" on public.calculations for select using (auth.uid() = user_id);
create policy "calculations_insert" on public.calculations for insert with check (auth.uid() = user_id);
create policy "calculations_update" on public.calculations for update using (auth.uid() = user_id);
create policy "calculations_delete" on public.calculations for delete using (auth.uid() = user_id);

-- 7. Teklifler
create table if not exists public.quotations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  ref_no text not null,
  customer text default '',
  total_eur numeric default 0,
  genel_toplam numeric default 0,
  item_count int default 1,
  created_at timestamptz default now()
);

alter table public.quotations enable row level security;
create policy "quotations_select" on public.quotations for select using (auth.uid() = user_id);
create policy "quotations_insert" on public.quotations for insert with check (auth.uid() = user_id);
create policy "quotations_update" on public.quotations for update using (auth.uid() = user_id);
create policy "quotations_delete" on public.quotations for delete using (auth.uid() = user_id);

-- 8. Teklif Sıra Numarası
create table if not exists public.teklif_seq (
  user_id uuid references auth.users(id) on delete cascade primary key,
  seq int default 0
);

alter table public.teklif_seq enable row level security;
create policy "teklif_seq_select" on public.teklif_seq for select using (auth.uid() = user_id);
create policy "teklif_seq_insert" on public.teklif_seq for insert with check (auth.uid() = user_id);
create policy "teklif_seq_update" on public.teklif_seq for update using (auth.uid() = user_id);

-- Atomik teklif numarası artırma fonksiyonu
create or replace function public.next_teklif_no()
returns int as $$
declare
  new_seq int;
  uid uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  insert into public.teklif_seq (user_id, seq) values (uid, 1)
  on conflict (user_id) do update set seq = teklif_seq.seq + 1
  returning seq into new_seq;
  return new_seq;
end;
$$ language plpgsql security definer;
