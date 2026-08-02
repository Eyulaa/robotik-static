-- =============================================================
-- ROBOTIK HUB — Supabase Setup Script
-- =============================================================
-- Cara pakai:
-- 1. Buka project Supabase kamu -> menu "SQL Editor"
-- 2. Klik "New query", tempel SELURUH isi file ini
-- 3. Klik "Run"
-- =============================================================

-- Aktifkan extension untuk generate UUID (biasanya sudah aktif)
create extension if not exists "pgcrypto";

-- -------------------------------------------------------------
-- Tabel utama: projects
-- -------------------------------------------------------------
create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  name text,
  title text not null,
  category text not null check (category in ('arduino', 'robotik')),
  description text not null,
  code text,
  video_url text,
  link_url text,
  file_path text,
  file_original_name text,
  image_path text,
  created_at timestamptz not null default now()
);

-- Index supaya query filter kategori & urut tanggal lebih cepat
create index if not exists idx_projects_category on projects (category);
create index if not exists idx_projects_created_at on projects (created_at desc);

-- -------------------------------------------------------------
-- Row Level Security (RLS)
-- -------------------------------------------------------------
-- Karena situs ini publik (siapa saja boleh upload tanpa login),
-- kita izinkan SELECT & INSERT untuk semua orang (peran "anon"),
-- tapi TIDAK mengizinkan UPDATE atau DELETE lewat frontend — supaya
-- proyek yang sudah diupload tidak bisa diubah/dihapus sembarang
-- orang. Hapus data lewat dashboard Supabase (menu Table Editor)
-- kalau perlu moderasi.

alter table projects enable row level security;

drop policy if exists "Public read access" on projects;
create policy "Public read access"
  on projects for select
  using (true);

drop policy if exists "Public insert access" on projects;
create policy "Public insert access"
  on projects for insert
  with check (true);

-- (Sengaja tidak dibuat policy UPDATE/DELETE, jadi otomatis ditolak)

-- -------------------------------------------------------------
-- Storage bucket untuk file & foto proyek
-- -------------------------------------------------------------
-- Bucket tidak selalu bisa dibuat lewat SQL di semua project,
-- jadi buat manual lewat dashboard:
--   Menu "Storage" -> "New bucket"
--   Nama bucket : project-files
--   Public bucket : ON (centang/aktifkan)
--
-- Setelah bucket dibuat, jalankan policy di bawah ini supaya
-- semua orang boleh membaca & mengupload file ke bucket tersebut.

drop policy if exists "Public read files" on storage.objects;
create policy "Public read files"
  on storage.objects for select
  using (bucket_id = 'project-files');

drop policy if exists "Public upload files" on storage.objects;
create policy "Public upload files"
  on storage.objects for insert
  with check (bucket_id = 'project-files');

-- Selesai! Lanjutkan ke langkah "Buat bucket Storage" di README.md
-- kalau belum, lalu isi config.js dengan URL & anon key project kamu.
