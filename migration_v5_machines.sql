-- ==========================================
-- FlexiCost v5 — Makine Kartları Migration
-- Supabase Dashboard → SQL Editor'de çalıştırın
-- ÖNEMLI: Bu v4 migration.sql'den sonra çalıştırılır
-- ==========================================

-- 1. Makine Kartları tablosu
-- Her kullanıcı birden fazla makine tanımlayabilir
-- Her teknoloji için bir makine "varsayılan" olarak işaretlenir
create table if not exists public.machines (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,

  -- Kimlik
  name text not null,
  technology text not null check (technology in ('rotogravur', 'flekso', 'dijital')),
  is_default boolean default false,

  -- Baskı geometrisi
  web_width numeric default 0,          -- baskı eni (mm)
  min_print_length numeric default 0,   -- min baskı boyu (mm)
  max_print_length numeric default 0,   -- max baskı boyu (mm)

  -- Hız ve kapasite
  max_speed numeric default 0,          -- max mekanik hız (m/dk)
  rec_speed numeric default 0,          -- tavsiye üretim hızı (m/dk)
  rpm numeric default 0,                -- devir

  -- Setup ve fire
  setup_time_min numeric default 0,     -- setup süresi (dk)
  changeover_time_min numeric default 0,-- iş değişim süresi (dk)
  setup_waste_m numeric default 0,      -- setup fire metre
  color_prep_time_min numeric default 0,-- renk başına ilave hazırlık (dk)

  -- Maliyet (saatlik)
  operator_count int default 1,
  hourly_labor numeric default 0,       -- €/saat
  hourly_energy numeric default 0,      -- €/saat
  hourly_overhead numeric default 0,    -- €/saat (makine genel gider)

  -- Verimlilik
  efficiency_pct numeric default 85,    -- verimlilik %
  yield_pct numeric default 95,         -- randıman %
  planned_downtime_pct numeric default 5,-- planlı duruş %

  -- İş karakteri
  min_economic_qty int default 0,       -- min ekonomik sipariş adet
  quality_risk numeric default 1,       -- kalite riski katsayısı
  rework_risk numeric default 1,        -- tekrar işleme riski

  -- Notlar
  notes text default '',

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Her kullanıcı + teknoloji için sadece bir default makine olsun
create unique index if not exists idx_machines_default
  on public.machines (user_id, technology)
  where is_default = true;

alter table public.machines enable row level security;
create policy "machines_select" on public.machines for select using (auth.uid() = user_id);
create policy "machines_insert" on public.machines for insert with check (auth.uid() = user_id);
create policy "machines_update" on public.machines for update using (auth.uid() = user_id);
create policy "machines_delete" on public.machines for delete using (auth.uid() = user_id);

-- 2. Quotation ve calculations tablolarına machine referansı ekle (opsiyonel ama önerilir)
-- Böylece hangi teklif/hesaplama hangi makineyle yapıldı takip edilebilir
alter table public.calculations
  add column if not exists machine_id uuid references public.machines(id) on delete set null;

alter table public.quotations
  add column if not exists machine_id uuid references public.machines(id) on delete set null,
  add column if not exists technology text;
