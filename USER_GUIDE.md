# 📱 Panduan Penggunaan Aplikasi Mobile (User Guide)

Aplikasi mobile ini dirancang untuk mempermudah pengguna (admin/analis) dalam mengelola siklus pemrosesan data dan pelatihan model *Machine Learning* (AI Pipeline) secara jarak jauh (*remote*) menggunakan antarmuka yang ramah pengguna.

Berikut adalah panduan lengkap alur penggunaan aplikasi dari awal hingga akhir.

---

## 🧭 Navigasi Utama (Dashboard)
Saat pertama kali membuka aplikasi, Anda akan disambut oleh halaman **Dashboard**. 
Halaman ini menampilkan ringkasan informasi dan jalan pintas ke fitur-fitur utama:
- **Statistik Cepat**: Menampilkan total data masuk, diproses, dan selesai (dummy/ringkasan).
- **Menu Utama**: Terdapat dua menu utama yaitu **Penerimaan Data API** dan **Pemrosesan & Training Model**.

---

## 🛠️ Langkah 1: Mengunggah Dataset Baru (Penerimaan Data API)
Langkah pertama dalam sistem ini adalah memasukkan dataset mentah yang ingin diolah.

1. Buka menu **Penerimaan Data API** dari Dashboard.
2. Di halaman ini, Anda dapat mengisi detail pekerjaan seperti Judul, Deskripsi, Kontak, dan Urgensi.
3. Klik tombol **Unggah File** (dengan ikon folder) untuk memilih file dataset berektensi **`.csv`** dari penyimpanan perangkat Anda.
4. Setelah file terpilih, nama file akan muncul di layar.
5. Klik tombol **Kirim ke Proses → 1** yang berada di bagian bawah.
6. Aplikasi akan mengirim file tersebut ke Backend (Django) dan sistem akan membuat ID Pekerjaan (*Job ID*) baru dengan status awal `pending`.

---

## ⚙️ Langkah 2: Mengelola Pelatihan Model (Pemrosesan & Training)
Setelah dataset berhasil diunggah, langkah selanjutnya adalah memulai proses pelatihan mesin (*Machine Learning*).

1. Buka menu **Pemrosesan & Data Entry** dari Dashboard.
2. Anda akan melihat daftar semua tugas/pekerjaan yang pernah dikirim. Tugas yang baru saja Anda unggah akan berada di posisi atas dengan status `pending` atau `Diterima`.
3. Klik pada tugas tersebut untuk membuka halaman **Detail Pekerjaan**.
4. Di dalam halaman detail, Anda akan melihat informasi file yang diunggah.
5. **Konfigurasi Training**: 
   - Pilih algoritma yang diinginkan (contoh: *Logistic Regression*, *Random Forest*, atau *SVM*).
   - Ketikkan nama **Target Column** (Kolom Target) yang ada di dalam file CSV Anda (misalnya: `diagnosis`, `label`, `harga`, dll).
6. Klik tombol **Mulai Pemrosesan Data & Training**.
7. Sistem Backend akan secara otomatis melakukan pembersihan data (*preprocessing*), ekstraksi fitur, pemodelan, dan evaluasi hasil.
8. Status pekerjaan akan berubah menjadi `completed` jika berhasil.

---

## 📊 Langkah 3: Melihat Hasil & Mengunduh Model
Setelah model selesai dilatih, Anda dapat melihat hasil evaluasinya langsung dari aplikasi.

1. Buka kembali halaman **Detail Pekerjaan** yang statusnya sudah `completed`.
2. Di layar, Anda akan melihat **Metrik Akurasi** (contoh: Akurasi: 95%).
3. **Mengunduh Berkas**:
   - Klik **Unduh Model (.pkl)** untuk menyimpan file model kecerdasan buatan siap pakai ke perangkat Anda.
   - Klik **Laporan PDF** untuk mengunduh laporan detail berformat PDF yang berisi matriks kebingungan (*confusion matrix*) dan metrik kinerja lainnya.
4. Aplikasi akan secara otomatis membuka *browser* bawaan HP untuk melakukan proses pengunduhan (*download*) langsung dari server Backend.

---

## 💡 Catatan Tambahan
- Pastikan HP (atau Emulator) Anda memiliki akses jaringan yang sama dengan server Backend Django (berada di jaringan WiFi yang sama, atau menggunakan koneksi `10.0.2.2` untuk emulator bawaan).
- Format data yang didukung penuh oleh sistem saat ini adalah `.csv`. Pastikan penamaan kolom rapi tanpa spasi kosong yang tidak perlu.
