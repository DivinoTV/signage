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

## Bagian 3 — GitHub Pages

Ini yang menyajikan halaman ke TV. Juga gratis.

**3.1** Buat akun di [github.com](https://github.com) kalau belum punya.

**3.2** Buat repository baru:
- Nama: `signage`
- **Public** — GitHub Pages tier gratis mewajibkan public.
- Jangan centang opsi tambahan apa pun (README, .gitignore, license). Repo harus kosong.

> Repo ini akan bisa dibaca siapa saja, dan itu tidak masalah selama isinya cuma ini:
> kode, artwork, dan anon key. Yang tidak boleh masuk: `service_role` key, rate card,
> dan data tamu.

**3.3** Unggah isi folder ini. Di Terminal, jalankan satu per satu:

```bash
cd "/Users/Marketing/Documents/Claude/Projects/Social Media Marketing/Hotel TV Display Project"
```

```bash
git init -b main && git add -A && git commit -m "Initial signage system"
```

Ganti `USERNAME` dengan username GitHub Anda:

```bash
git remote add origin https://github.com/USERNAME/signage.git && git push -u origin main
```

Kalau diminta login, GitHub akan membuka browser. Ikuti saja.

**3.4** Nyalakan Pages. Di halaman repo → **Settings** → **Pages** → bagian Source pilih
**Deploy from a branch**, branch **main**, folder **/ (root)**, lalu Save.

Tunggu 1–2 menit. Alamat Anda jadi:

```
https://USERNAME.github.io/signage/
```

**3.5** Buka alamat itu di laptop dulu. Yang benar: layar gelap dengan tulisan
`NO ?property= IN URL`. Itu **bukan** error — itu memang perilaku yang dirancang saat
properti belum disebut di URL. Artinya hosting sudah jalan.

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
