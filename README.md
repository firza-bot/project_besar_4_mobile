# AI Pipeline Mobile App 🚀

Aplikasi mobile (*native Flutter*) ini merupakan *frontend* pendamping untuk Sistem AI Pipeline (*Data Processing & Model Training*). Aplikasi ini berfungsi untuk melakukan pengaturan alur pemrosesan data, konfigurasi hiperparameter *machine learning*, dan memantau status *training* secara *real-time*.

## Persyaratan Sistem
Karena aplikasi ini bergantung pada Backend (Django) untuk memproses *machine learning*, **pastikan repository Backend sudah berjalan terlebih dahulu**.

- **Backend Repository**: [project_besar_4](https://github.com/firza-bot/project_besar_4)
- **Flutter SDK**: Versi 3.19.0 atau yang lebih baru.

## Cara Menjalankan untuk Dosen / Penguji

### 1. Jalankan Backend (Django)
Pastikan Backend sudah berjalan di lokal komputer Anda (biasanya di `http://127.0.0.1:8000`).
```bash
python manage.py runserver 0.0.0.0:8000
```

### 2. Konfigurasi IP Backend di Mobile App
Secara *default*, aplikasi mobile ini sudah di-setting untuk menembak ke *localhost* dari **Emulator Android bawaan laptop** (yaitu `10.0.2.2:8000`). 
Buka file `lib/services/api_service.dart`, lalu pastikan baris ini sesuai dengan metode pengetesan Anda:

```dart
// Jika menggunakan Emulator bawaan Android Studio:
final String baseUrl = 'http://10.0.2.2:8000';

// Jika menggunakan HP Fisik (harus satu WiFi dengan laptop yang menjalankan backend):
// final String baseUrl = 'http://192.168.x.x:8000'; // Sesuaikan dengan IP WiFi laptop Anda
```

### 3. Build & Jalankan Aplikasi
Buka terminal di folder project ini, lalu jalankan:

```bash
flutter pub get
flutter run
```

Atau untuk mem-build APK secara langsung (Release):
```bash
flutter build apk --release
```
File APK akan berada di: `build/app/outputs/flutter-apk/app-release.apk`

---
*Dibuat untuk memenuhi tugas Project Besar Semester 4.*
