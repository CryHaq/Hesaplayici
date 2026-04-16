-- ==========================================
-- FlexiCost v5 — Müşteri Segmentleri
-- Supabase Dashboard → SQL Editor'de çalıştırın
-- ==========================================

-- clients tablosuna segment ve marj katsayısı ekle
alter table public.clients
  add column if not exists segment text default 'yurtici' check (segment in ('yurtici','ihracat','stratejik','deneme')),
  add column if not exists margin_pct numeric default 15,      -- hedef kâr marjı %
  add column if not exists discount_pct numeric default 0,     -- uygulanabilecek iskonto %
  add column if not exists payment_days int default 0;          -- vade (0 = peşin, 30/60/90)
