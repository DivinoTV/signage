# Cara Membuat & Menerbitkan Slide

Untuk Samuel. Semua teks dibakar ke dalam artwork — halaman TV hanya mengurus urutan dan
pergantian antar slide. Gambarnya statis — tidak ada gerakan sama sekali. Jadi kualitas
tampilan sepenuhnya ditentukan di tahap desain.

---

## 1. Ukuran & area aman

- Kanvas **1920 × 1080** px, landscape. Selalu. Tidak ada ukuran lain.
- **Sisakan 5% kosong dari setiap tepi.** Artinya semua yang penting harus berada di
  dalam `x: 96–1824` dan `y: 54–1026`.

TV consumer sering memotong tepi gambar (overscan). Margin 5% itu yang menjaga logo,
QR, dan teks Anda tidak terpotong.

---

## 2. Ukuran huruf — ini yang paling sering salah

Tamu menonton dari jarak **2,5–3,5 meter**. Di jarak itu huruf yang terlihat wajar di
layar laptop menjadi tidak terbaca sama sekali.

| Peran | Minimum di kanvas 1920 × 1080 |
|---|---|
| Judul | 96 px |
| Sub-judul | 56 px |
| Teks isi | **36 px — batas mati, jangan di bawah ini** |
| Panjang baris | maksimal 40 karakter |
| Jumlah baris per slide | maksimal 6 |

**Contoh nyata dari artwork Divino Gili Air:** paragraf panjangnya berukuran sekitar
20–22 px dengan baris ~83 karakter. Di kamar, paragraf itu praktis tidak terbaca. Untuk
perannya sebagai slide offline masih bisa diterima — tugasnya cuma "menampilkan sesuatu"
saat sistem mati. Tapi kalau artwork sejenis dipakai sebagai slide reguler, teksnya harus
naik dan kalimatnya dipendekkan.

Aturan praktis: kalau satu slide butuh paragraf, slide itu terlalu ramai. Pecah jadi dua,
atau pindahkan detailnya ke balik QR code.

---

## 3. Warna & kontras

- Kamar hotel **gelap saat malam**. Latar gelap dengan teks terang jauh lebih nyaman
  daripada sebaliknya.
- Kalau menaruh teks di atas foto, pakai **blok warna solid** di belakangnya. Gradient
  halus akan terlihat bergaris-garis (banding) di panel TV, walau mulus di laptop.

---

## 4. Ekspor file

**Gambar** — JPEG atau WebP, sisi terpanjang 1920 px, **300–500 KB per file**.

Kalau hasil ekspor jauh di atas itu, turunkan kualitas JPEG-nya. File besar membakar
kuota egress dan itu batasan paling sempit di seluruh sistem.

Ini bukan anjuran kosmetik. Terukur pada tiga slide pertama Divino Gili Air: aslinya
0,95–1,45 MB per file, total 3,59 MB satu putaran. Dikompresi ke dalam spec jadi 1,27 MB —
dan proyeksi egress untuk 22 TV turun dari ~2,6 GB jadi ~1,2 GB per bulan, dari plafon 5 GB.
Selisih itulah ruang untuk properti kedua dan ketiga.

**Kalau hasil ekspor kebesaran, kompres dari Terminal** — tidak perlu buka aplikasi desain
lagi. Ganti angka `70` sampai ukurannya masuk 300–500 KB (angka lebih kecil = file lebih
kecil):

```bash
sips -s format jpeg -s formatOptions 70 masukan.jpg --out keluaran.jpg && ls -lh keluaran.jpg
```

Kualitas yang pas berbeda per gambar: foto dengan banyak detail butuh angka lebih rendah,
desain berlatar rata bisa lebih tinggi. Untuk ketiga slide pertama angkanya ternyata 68, 56,
dan 80.

**Kalau gambarnya memuat QR code, cek ulang setelah dikompresi** — scan sendiri pakai HP.
Kompresi terlalu keras bisa merusak QR tanpa terlihat rusak oleh mata.

**Video** — tanpa suara, 15–25 detik. Jalankan ini di Terminal:

```bash
ffmpeg -i input.mov -c:v libx264 -profile:v high -pix_fmt yuv420p -vf "scale=1920:1080,fps=30" -b:v 6M -maxrate 8M -bufsize 12M -an -movflags +faststart output.mp4
```

`-an` itu yang membuang audio, dan itu wajib: browser memblokir autoplay pada video yang
punya jalur audio. Batas keras 50 MB per file dan tidak bisa dinaikkan.

> Video baru boleh dipakai setelah gate G1, G2, dan G4 lulus di TV asli. Sebelum itu,
> baris video akan dilewati oleh TV dan dicatat di log. Lihat [GATES.md](GATES.md).

**QR code** — generate dari URL yang bersih. Jangan copy link dari Facebook atau
Instagram; link dari sana membawa parameter pelacakan panjang (`?fbclid=...`) yang
membuat QR jadi padat dan susah discan dari layar TV, sekaligus mengotori statistik Anda.
URL pendek = kotak QR lebih besar = jauh lebih mudah discan.

---

## 5. Cek cepat sebelum upload

- [ ] Tepat 1920 × 1080
- [ ] Tidak ada isi penting di dalam 96 px dari tepi kiri/kanan, 54 px dari atas/bawah
- [ ] Teks isi minimal 36 px, baris maksimal 40 karakter
- [ ] Gambar 300–500 KB, atau video ≤ 50 MB tanpa audio
- [ ] Kalau ada QR: sudah discan sendiri pakai HP, dan URL-nya bersih

---

## 6. Terbitkan

1. Buka admin panel, login.
2. Pilih properti.
3. Pilih file, set **Category / Area** dan **Duration**.
   - **All categories** = tampil di semua TV properti itu. Ini yang paling sering dipakai.
   - Kategori tertentu = hanya TV di kategori kamar itu. Pakai ini hanya untuk hal yang
     memang beda, misal fasilitas kamar atau penawaran upgrade.
4. Klik **Upload and publish**.
5. Kalau slide ini ada masa berlaku, isi **Show from** dan **Hide after**. Slide akan
   muncul dan hilang sendiri, tanpa Anda perlu ingat mematikannya.
6. Atur urutan dengan tombol ↑ / ↓.
7. Cek di satu TV. Perubahan masuk dalam waktu maksimal 5 menit.
8. **KLIK EXPORT.**

---

## 7. Kenapa langkah 8 tidak boleh dilewat

Tier gratis Supabase **tidak punya backup sama sekali**. File JSON dari tombol Export itu
satu-satunya backup yang ada. Kalau ada yang terhapus dan tidak ada export terbaru, konten
itu hilang permanen.

Simpan file export di tempat yang Anda percaya. Menaruhnya di folder project lalu
`git push` juga boleh — gratis, tersimpan di luar laptop, dan punya riwayat versi.

---

## Kalau ada yang salah tayang

| Situasi | Tindakan |
|---|---|
| Slide salah sudah tayang | Klik **Hide from TVs**. Hilang dalam maksimal 5 menit. Ini yang paling aman. |
| File yang diupload keliru | Upload file yang benar sebagai slide baru, lalu sembunyikan yang lama. Jangan pernah menimpa file. |
| Konten terhapus tidak sengaja | Ambil dari file JSON export terbaru. |

Tombol **Delete** membuang baris databasenya **dan** file gambarnya sekaligus, dan itu
permanen — tier gratis tidak punya backup, dan file export hanya bisa memulihkan barisnya,
bukan gambarnya. Kalau ragu, pakai **Hide from TVs** dulu: itu bisa dibatalkan.

Dua pengaman ada di sana: file yang dipakai slide lain tidak akan dihapus, dan file yang
di-host di luar Supabase tidak disentuh sama sekali.
