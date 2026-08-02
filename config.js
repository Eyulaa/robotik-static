# Robotik Hub — Versi Static Site (Supabase)

Versi ini adalah website **statis murni** (HTML/CSS/JS saja, tanpa server)
yang bisa kamu upload ke GitHub Pages, Netlify, Vercel, atau hosting statis
apapun. Fitur upload proyek tetap benar-benar berfungsi karena database dan
penyimpanan file memakai **Supabase** (gratis untuk skala kecil–menengah),
dipanggil langsung dari browser.

---

## Bagian 1 — Setup Supabase (sekali saja)

### 1. Buat akun & project

1. Buka [supabase.com](https://supabase.com) → daftar/login (bisa pakai akun GitHub).
2. Klik **New project**.
3. Isi nama project (bebas, misal `robotik-hub`), buat password database (simpan, tidak dipakai di sini tapi wajib diisi), pilih region terdekat (misal Singapore).
4. Tunggu 1–2 menit sampai project selesai dibuat.

### 2. Jalankan script database

1. Di sidebar kiri, klik **SQL Editor**.
2. Klik **New query**.
3. Buka file `supabase/schema.sql` dari folder project ini, salin **seluruh isinya**, tempel ke editor.
4. Klik **Run** (atau tekan Ctrl/Cmd + Enter).
5. Pastikan muncul pesan sukses tanpa error.

### 3. Buat Storage bucket

1. Di sidebar kiri, klik **Storage**.
2. Klik **New bucket**.
3. Nama bucket: `project-files` (harus persis sama).
4. Aktifkan toggle **Public bucket** → ON.
5. Klik **Create bucket**.

> Policy akses bucket ini sudah otomatis diatur lewat `schema.sql` di langkah sebelumnya (bagian storage.objects policy).

### 4. Ambil URL & API key

1. Di sidebar kiri, klik ikon gerigi **Project Settings** → **API**.
2. Salin nilai **Project URL**.
3. Salin nilai **anon public** (di bagian "Project API keys").

---

## Bagian 2 — Konfigurasi website

1. Buka file `config.js` di folder project ini.
2. Ganti dua baris berikut dengan nilai dari Supabase kamu:

```js
const SUPABASE_URL = 'https://xxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

3. Simpan file.

Itu saja — tidak ada langkah build/compile, karena ini murni HTML/CSS/JS.

---

## Bagian 3 — Coba dulu di komputer sendiri (opsional tapi disarankan)

Karena browser modern membatasi beberapa hal saat file dibuka langsung
(`file://`), sebaiknya jalankan lewat server lokal sederhana:

```bash
# Kalau punya Python 3:
python3 -m http.server 8000

# atau kalau punya Node.js:
npx serve .
```

Lalu buka `http://localhost:8000` di browser dan coba upload satu proyek
untuk memastikan semuanya tersambung dengan benar.

---

## Bagian 4 — Deploy ke hosting statis

Pilih salah satu:

### Opsi A: Netlify (paling mudah)
1. Buka [app.netlify.com](https://app.netlify.com) → daftar/login.
2. Drag-and-drop seluruh folder project ini ke halaman "Deploys".
3. Selesai — Netlify langsung memberi URL publik.

### Opsi B: GitHub Pages
1. Buat repository baru di GitHub, upload semua file di folder ini (termasuk `config.js` yang sudah diisi).
2. Buka **Settings → Pages** di repo tersebut.
3. Pilih branch `main` dan folder `/ (root)`, klik **Save**.
4. Tunggu beberapa menit, situs akan tersedia di `https://username.github.io/nama-repo/`.

### Opsi C: Vercel
1. Buka [vercel.com](https://vercel.com) → **Add New Project**.
2. Hubungkan repo GitHub kamu (atau drag-drop folder lewat CLI `vercel`).
3. Karena tidak ada proses build, biarkan pengaturan default (static).

---

## Struktur folder

```
robotik-hub-static/
├── index.html          # Halaman utama
├── style.css            # Styling
├── app.js                 # Logika frontend + panggilan ke Supabase
├── config.js                # ISI INI dengan URL & anon key Supabase kamu
└── supabase/
    └── schema.sql             # Script setup tabel & storage policy
```

---

## Batasan & catatan penting

- **Situs ini publik terbuka**: siapa saja bisa upload tanpa login, sesuai
  permintaan awal. Data TIDAK bisa diubah/dihapus dari frontend (sengaja
  dibatasi lewat RLS) — untuk moderasi/hapus konten, lakukan lewat dashboard
  Supabase di menu **Table Editor** (tabel `projects`) dan **Storage**.
- **`config.js` berisi kunci publik ("anon key")** — ini memang didesain
  aman untuk ditaruh di frontend/browser, karena akses sebenarnya dibatasi
  oleh aturan RLS di database, bukan oleh kerahasiaan key ini.
- **Batas gratis Supabase** (per Agustus 2026, bisa berubah — cek
  [supabase.com/pricing](https://supabase.com/pricing) untuk info terbaru):
  sekitar 500MB database dan 1GB storage file di paket gratis. Cukup untuk
  ratusan proyek teks + puluhan-ratusan file kecil–menengah.
- Kalau nanti butuh fitur akun/login supaya orang hanya bisa hapus/edit
  proyek mereka sendiri, atau butuh dashboard moderasi di dalam website
  (bukan lewat dashboard Supabase), itu bisa ditambahkan — tinggal bilang.

---

Selamat berbagi proyek! 🤖🔧
