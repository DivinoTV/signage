# Panduan Setup — untuk Samuel

Ditulis untuk dikerjakan tanpa latar belakang teknis. Ikuti berurutan; setiap bagian
menghasilkan sesuatu yang dibutuhkan bagian berikutnya.

Perkiraan waktu: sekitar 45 menit untuk Bagian 1–3, lalu Bagian 4 butuh naik ke satu
kamar hotel.

Catatan: Supabase dan GitHub kadang mengubah nama tombol dan tata letak menunya. Kalau
label yang Anda lihat tidak persis sama dengan yang saya tulis, cari yang fungsinya
sama — urutan langkahnya tetap benar.

---

## Bagian 1 — Supabase

Ini tempat data, gambar, dan login disimpan. Gratis, dan **tidak perlu kartu kredit**.
Kalau di titik mana pun Anda diminta memasukkan kartu, berhenti dan beri tahu saya —
berarti ada yang salah pilih.

**1.1** Buka [supabase.com](https://supabase.com), daftar pakai email Anda.

**1.2** Buat project baru.
- Nama: `signage` (bebas, tapi ini memudahkan)
- Password database: klik tombol generate, lalu **simpan di password manager Anda**.
  Ini bukan password login Anda dan jarang dipakai, tapi kalau hilang tidak bisa diambil lagi.
- Region: pilih **Singapore** — paling dekat ke Indonesia, jadi paling cepat.
- Tunggu 1–2 menit sampai project selesai dibuat.

> Satu project melayani keenam properti. **Jangan** bikin project per brand — tier gratis
> hanya mengizinkan 2 project aktif, dan memecahnya akan menghabiskan kuota tanpa
> menyisakan ruang untuk staging.

**1.3** Buat tabelnya. Di menu sebelah kiri cari **SQL Editor**, lalu jalankan tiga file
ini **berurutan** — buka filenya, copy seluruh isinya, paste, klik Run:

1. `db/schema.sql`
2. `db/policies.sql`
3. `db/seed-zones.sql`

Setiap kali harus muncul pesan sukses. Kalau ada error merah, jangan lanjut — kirim
pesan errornya ke saya.

**1.4** Buat tempat penyimpanan gambar. Menu kiri → **Storage** → buat bucket baru:
- Nama: **`signage`** (harus persis ini, huruf kecil semua)
- Setel bucket sebagai **public**. Ini aman dan memang disengaja: TV harus bisa
  mengambil gambar tanpa login. Yang dilindungi adalah kemampuan *mengubah*, bukan melihat.

**1.5** Buat akun operator Anda. Menu kiri → **Authentication** → daftar user → tambah
user baru secara manual:
- Email: email yang akan Anda pakai untuk login ke admin panel
- Password: buat yang kuat, simpan di password manager

> **Jangan kirim password ini ke saya.** Saya tidak membutuhkannya dan tidak boleh
> menyimpannya. Kalau nanti ada langkah yang seolah butuh password Anda, itu keliru —
> tanyakan dulu.

**1.6** **Matikan pendaftaran publik.** Ini langkah paling penting di seluruh panduan.
Authentication → pengaturan provider Email → matikan opsi yang mengizinkan user baru
mendaftar sendiri.

Kalau ini dibiarkan terbuka, siapa pun di internet bisa mendaftar, otomatis dapat status
`authenticated`, dan lolos semua aturan tulis — termasuk menghapus seluruh konten signage
di enam properti. Kunci anon yang tertanam di halaman TV memang bisa dibaca siapa saja;
yang menahan mereka hanyalah RLS ditambah pendaftaran yang tertutup.

**1.7** Ambil dua nilai yang saya butuhkan. Menu kiri → **Settings** → **API** (atau
**API Keys**). Catat:

| Yang dicari | Bentuknya |
|---|---|
| **Project URL** | `https://sesuatu.supabase.co` |
| **anon key** / **publishable key** | teks sangat panjang, biasanya diawali `eyJ...` |

---

## Bagian 2 — Kirim ke saya

Kirimkan **Project URL** dan **anon key** di chat. Saya akan menuliskannya ke tiga file
yang membutuhkannya (`index.html`, `gate-test.html`, `admin/index.html`) supaya tidak ada
salah tempel.

Anon key ini **memang dirancang untuk publik** — dia toh ikut terbaca di halaman TV oleh
siapa pun yang melihat source. Jadi mengirimkannya bukan kebocoran.

> **Yang tidak boleh dikirim ke siapa pun, termasuk saya: `service_role` key** (kadang
> dinamai **secret key**). Kunci itu melewati semua aturan keamanan. Dia tidak boleh
> keluar dari dashboard Supabase, dan tidak boleh masuk ke repo ini. Kalau Anda pernah
> menempelkannya di mana pun, segera rotate dari dashboard.
>
> Cara membedakan: yang aman biasanya berlabel **anon** atau **publishable**. Yang
> berbahaya berlabel **service_role** atau **secret**, dan biasanya disembunyikan di
> balik tombol "reveal".

---

## Bagian 3 — GitHub Pages ✅ SELESAI

Dikerjakan 2026-08-13. Bagian ini tinggal catatan; tidak ada yang perlu Anda ulangi.

| | |
|---|---|
| Repo | [DivinoTV/signage](https://github.com/DivinoTV/signage) — **public** |
| Alamat live | `https://divinotv.github.io/signage/` |
| Admin panel | `https://divinotv.github.io/signage/admin/` |
| Sumber Pages | branch `main`, folder `/` (root) |

Repo harus public karena organisasi DivinoTV pakai plan gratis, dan GitHub Pages
mewajibkan public di plan itu. Isinya aman untuk publik: kode, artwork, dan kunci
publishable — yang memang dirancang publik (brief C6). Yang **tidak** ikut terbit,
dikecualikan lewat `.gitignore`: `API.md`, `PROJECT_BRIEF_v2.1.md`, dan `.claude/`.

### Cara mengirim perubahan berikutnya

Kalau nanti ada file yang diubah (artwork fallback baru, dokumen, atau `index.html`),
jalankan tiga perintah ini dari folder project:

```bash
cd "/Users/Marketing/Documents/Claude/Projects/Social Media Marketing/Hotel TV Display Project" && git add -A && git commit -m "jelaskan perubahannya di sini" && git push
```

Pages membangun ulang otomatis dalam ~30 detik.

> Kalau yang Anda ubah adalah `index.html`, naikkan juga angka di `version.json` **dan**
> `CFG.version` di dalam `index.html` pada commit yang sama. Itu yang memaksa TV yang
> sedang menyala memuat ulang halaman, tanpa menunggu dibuka lagi besok pagi.

---

## Bagian 4 — Uji keamanan

Wajib, dan menghalangi rilis. Di Terminal, ganti kedua nilai dengan milik Anda:

```bash
cd "/Users/Marketing/Documents/Claude/Projects/Social Media Marketing/Hotel TV Display Project" && ./verify-security.sh https://xxxx.supabase.co eyJhbG-anon-key-anda
```

Yang benar: **semua baris PASS**. Satu saja FAIL berarti sistem terbuka dan tidak boleh
dirilis — kirimkan hasilnya ke saya.

Jalankan ulang perintah ini setiap tiga bulan. Aturan keamanan bisa bergeser tanpa
disadari saat fitur ditambah.

---

## Bagian 5 — Uji di TV

Bagian ini tidak bisa dilewati dan tidak bisa digantikan tes di laptop. Ikuti
[GATES.md](GATES.md) — di situ ada satu halaman uji yang melaporkan hampir semua gate
sendiri, jadi cukup sekali naik ke kamar.

Dua hasil bisa menghentikan proyek, dan lebih baik ketahuan sekarang daripada setelah
40 TV dipasang:

- **Nomor model TV diawali `LH`** → itu TV signage komersial, bukan consumer. Kabar
  bagus sebetulnya: ada jalur bawaan yang jauh lebih sederhana (URL Launcher).
- **Jaringan TV pakai halaman login/captive portal** → harus diselesaikan dengan IT
  properti dulu. Tidak ada solusi dari sisi software.

---

## Kalau ada yang macet

Kirimkan ke saya: langkah nomor berapa, dan pesan error apa adanya (screenshot juga
boleh). Jangan menebak-nebak sendiri di dashboard Supabase — beberapa pengaturan di sana
sulit dikembalikan.
