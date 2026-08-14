# Pemasangan per TV

Satu lembar per TV. Kerjakan berurutan, lalu catat di tabel paling bawah.

Nama menu Samsung berbeda antar tahun produksi. Kalau label yang Anda lihat tidak persis
sama, cari yang fungsinya sama. Setelah TV pertama selesai, tulis jalur menu yang benar
di bagian "Catatan model" di bawah — TV berikutnya jadi jauh lebih cepat.

---

## Sebelum masuk kamar

- [ ] Gate di [GATES.md](GATES.md) sudah dijalankan dan hasilnya dicatat
- [ ] Uji keamanan `./verify-security.sh` semua PASS
- [ ] Sudah ada minimal satu slide aktif untuk properti ini di admin panel
- [ ] Tahu URL lengkap TV ini (lihat tabel di bawah)

---

## 1. Jaringan

- [ ] TV terhubung ke jaringan **staff / IoT**, **bukan WiFi tamu**

Ini bukan preferensi, ini syarat. WiFi tamu biasanya pakai halaman login (captive
portal) yang akan membajak browser setiap kali TV menyambung ulang, dan tidak ada solusi
software untuk itu.

- [ ] Pakai **kabel ethernet** kalau ada portnya. Lebih stabil daripada WiFi untuk
      perangkat yang menyala terus.

---

## 2. Matikan semua yang bisa mematikan layar

- [ ] `Auto Power Off` → **OFF**
- [ ] `Screen Saver` → **OFF**
- [ ] `Brightness Optimization` → **OFF**

Biasanya ada di sekitar menu **Power and Energy Saving**, tapi lokasinya berpindah antar
model. Ketiganya harus mati. Kalau ada satu yang tidak bisa dimatikan, catat dan beri
tahu Samuel — TV itu tidak cocok dipakai.

- [ ] Mode gambar diset dan dikunci. **Matikan motion smoothing** kalau ada — fitur itu
      membuat gerakan Ken Burns terlihat aneh.

---

## 3. Cek tepi layar (overscan)

- [ ] Buka `gate-test.html` di TV ini. Semua teks di keempat tepi harus terbaca.

Kalau ada tepi yang terpotong, cari pengaturan ukuran gambar TV (biasanya di menu Picture,
namanya seputar *Picture Size* atau *Screen Fit*) dan pilih opsi yang menampilkan gambar
utuh tanpa zoom. Catat pengaturannya di bawah.

---

## 4. Buka halamannya

- [ ] Home → Internet → masukkan URL lengkap TV ini

URL-nya berbentuk:

```
https://divinotv.github.io/signage/?property=PROPERTI&type=KATEGORI
```

Contoh untuk kamar Deluxe di Divino Gili Air:

```
https://divinotv.github.io/signage/?property=divino-gili-air&type=deluxe
```

Slug properti yang berlaku:

| Properti | Slug | Status |
|---|---|---|
| Divino Gili Air | `divino-gili-air` | beroperasi |
| Divino Caldera | `divino-caldera` | belum |
| Kanzen Gili Air | `kanzen-gili-air` | belum |
| Oniro | `oniro` | belum |

Properti yang belum beroperasi harus diaktifkan dulu di `db/seed-zones.sql` sebelum
TV-nya bisa dipasang.

Slug kategori untuk Divino Gili Air: `deluxe`, `junior-suite`, `king-suite`, `superior`.

- [ ] Set URL itu sebagai **homepage** browser
- [ ] **Bookmark** juga, sebagai jalur kedua kalau homepage gagal

Mengetik URL panjang pakai remote itu menyiksa dan rawan salah. Ketik sekali, teliti,
lalu jadikan homepage. Salah satu huruf di bagian `?property=` membuat TV menampilkan
slide offline, bukan error — jadi kalau yang muncul slide offline padahal konten sudah
ada, curigai salah ketik URL lebih dulu.

---

## 5. Uji

- [ ] Slide tampil dan berganti sendiri
- [ ] **Cabut listrik TV, nyalakan lagi.** Lalu: TV on → Home → Internet. Halaman harus
      kembali muncul dalam 3 langkah itu saja. Kalau butuh lebih, catat apa yang terjadi.
- [ ] Buka sekali dengan tambahan `&debug=1` di ujung URL. Periksa:
      - `property` dan `zone` sesuai
      - `playlist` jumlahnya masuk akal
      - `last fetch` menunjukkan waktu beberapa menit terakhir
- [ ] Kembalikan ke URL normal (tanpa `&debug=1`) dan pastikan itu yang jadi homepage

---

## 6. Catat

| Data | Isi |
|---|---|
| Model TV | |
| Nomor kamar | |
| Properti (slug) | |
| Kategori (slug) | |
| MAC address | |
| Kabel / WiFi | |
| Tanggal dipasang | |
| Dipasang oleh | |

Catatan ini penting. Sengaja tidak ada identitas per-TV yang ditanam di URL — nomor kamar
hanya hidup di lembar ini, dan lembar ini jauh lebih mudah dikoreksi daripada URL yang
sudah tertanam di bookmark 40 TV.

---

## Catatan model — isi setelah TV pertama

Jalur menu yang benar untuk model di properti ini:

- Auto Power Off:
- Screen Saver:
- Brightness Optimization:
- Picture size / screen fit:
- Browser menyimpan sesi setelah dicabut listrik? Ya / Tidak
- Halaman terbuka sendiri atau perlu 3 langkah manual?
