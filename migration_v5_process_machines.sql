-- ==========================================
-- FlexiCost v5 Faz 5 — Proses Makine Kartları
-- Supabase Dashboard → SQL Editor'de çalıştırın
-- ==========================================

-- 1. Technology CHECK constraint'i genişlet
-- Eski: 'rotogravur', 'flekso', 'dijital'
-- Yeni: + 'laminasyon', 'kesim', 'konverting'

alter table public.machines
  drop constraint if exists machines_technology_check;

alter table public.machines
  add constraint machines_technology_check
  check (technology in ('rotogravur', 'flekso', 'dijital', 'laminasyon', 'kesim', 'konverting'));

-- 2. Laminasyon özel alanı: tutkal maliyeti (€/kg laminat)
alter table public.machines
  add column if not exists lam_adhesive_rate numeric default 0;

-- 3. Konverting özel alanı: adet/dk bazlı hesap için hız birimi notu
-- (rec_speed alanı zaten var; konverting için "adet/dk" olarak yorumlanır,
-- diğerleri için "m/dk")
