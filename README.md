# MentorRide Mobile

MentorRide adalah aplikasi Android untuk mencatat kendaraan, riwayat servis,
biaya perawatan, jadwal servis, dan pengingat lokal. Seluruh data berasal dari
input pengguna dan disimpan per akun di Cloud Firestore.

## Fitur

- Registrasi, login, reset kata sandi, edit nama, dan logout dengan Firebase
  Authentication.
- CRUD kendaraan dan pilihan kendaraan aktif yang disimpan per pengguna.
- Riwayat servis dengan beberapa item per transaksi, total biaya otomatis,
  filter bulan/tahun, serta pembaruan odometer kendaraan secara transaksional.
- Jadwal servis dengan tanggal atau kilometer jatuh tempo, pengingat lokal,
  status selesai, dan ID notifikasi yang stabil.
- Dashboard kendaraan aktif, servis terakhir, jadwal terdekat, biaya bulan dan
  tahun berjalan, serta grafik biaya enam bulan.
- Antarmuka Material 3 berbahasa Indonesia dengan loading, error, empty state,
  validasi formulir, snackbar, dan dialog konfirmasi.

## Teknologi

- Flutter 3.44 atau lebih baru dan Dart 3.12 atau lebih baru
- Material 3 dan `flutter_localizations`
- Riverpod tanpa code generation
- GoRouter dengan redirect autentikasi
- Firebase Core, Authentication, dan Cloud Firestore
- `flutter_local_notifications` dan `timezone` untuk Asia/Jakarta
- `shared_preferences`, `uuid`, `intl`, dan `fl_chart`

## Struktur folder

```text
lib/
├── app/                         tema, router, dan root aplikasi
├── core/                        Firebase, error, notifikasi, storage, utilitas
├── features/
│   ├── auth/                    autentikasi dan profil pengguna
│   ├── dashboard/               agregasi dan tampilan beranda
│   ├── navigation/              shell bottom navigation
│   ├── profile/                 profil, izin notifikasi, dan logout
│   ├── service_records/         riwayat servis dan biaya
│   ├── service_schedules/       jadwal dan pengingat lokal
│   └── vehicles/                kendaraan dan pilihan aktif
├── shared/                      widget yang digunakan lintas fitur
├── firebase_options.dart        konfigurasi klien hasil FlutterFire
└── main.dart                    bootstrap Firebase dan notifikasi
```

Setiap fitur memisahkan model/domain, adapter data atau repository, provider,
controller/service bila diperlukan, dan layar presentasi. Model menggunakan
`fromMap`, `toMap`, dan `copyWith` tanpa code generation.

## Struktur Cloud Firestore

```text
users/{uid}
├── displayName, email, createdAt, updatedAt
└── vehicles/{vehicleId}
    ├── name, brand, model, year, plateNumber, currentOdometer
    ├── createdAt, updatedAt
    ├── service_records/{recordId}
    │   ├── serviceDate, odometer, workshop, items, totalCost, notes
    │   └── createdAt, updatedAt
    └── service_schedules/{scheduleId}
        ├── title, serviceType, dueDate, dueOdometer
        ├── reminderAt, reminderEnabled, localNotificationId, status
        └── createdAt, updatedAt
```

Nominal Rupiah, kilometer, tahun, dan ID notifikasi disimpan sebagai integer.
`createdAt` dan `updatedAt` ditulis dengan `FieldValue.serverTimestamp()` dan
dapat sementara bernilai `null` sebelum write lokal dikonfirmasi server.

## Konfigurasi Firebase

Repository sudah mengharapkan konfigurasi FlutterFire Android berikut:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- application ID `com.mentorrideapp.mentorride`

Jika salah satu konfigurasi belum tersedia atau proyek Firebase perlu diganti,
jalankan FlutterFire CLI untuk Android dan gunakan nilai yang dihasilkan oleh
Firebase. Jangan membuat API key, app ID, UID, akun, atau kredensial sendiri.

```bash
flutterfire configure --platforms=android
```

Di Firebase Console, aktifkan:

1. Authentication dengan provider Email/Password.
2. Cloud Firestore untuk database `(default)`.

Jangan menaruh service-account key, Firebase Admin SDK key, `.env`, Android
keystore, token, atau kredensial lokal di repository. Konfigurasi klien
FlutterFire bukan service-account key.

## Menjalankan aplikasi

Pastikan Flutter SDK, Android SDK, dan perangkat atau emulator Android tersedia.

```bash
flutter pub get
flutter run
```

Notifikasi memakai zona `Asia/Jakarta` dan mode penjadwalan Android yang tidak
memerlukan izin exact alarm. Android 13 atau lebih baru akan meminta izin
notifikasi saat pengguna mengaktifkan pengingat. Pengingat dibatalkan ketika
jadwal diedit, dihapus, ditandai selesai, kendaraannya dihapus, atau pengguna
logout.

## Firestore Security Rules

`firestore.rules` hanya mengizinkan pengguna terautentikasi mengakses dokumen
`users/{uid}` dan seluruh turunannya ketika `request.auth.uid == uid`. Semua
path lain ditolak. Query saat ini tidak memerlukan compound index, sehingga
`firestore.indexes.json` tetap kosong.

Tinjau proyek Firebase aktif sebelum menjalankan perintah berikut secara manual:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Tidak ada deploy otomatis dari aplikasi atau workflow repository ini.

## Validasi

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Pengujian unit tidak mengakses proyek Firebase live. Repository dan scheduler
notifikasi diuji melalui fake yang berada di folder `test/`.

## Catatan pengembangan

- Platform awal adalah Android dan seluruh teks pengguna harus berbahasa
  Indonesia.
- Firestore tidak menghapus subcollection secara otomatis; penghapusan
  kendaraan menggunakan cascade delete dan membatalkan pengingat turunannya.
- Mengedit atau menghapus riwayat servis tidak menurunkan odometer kendaraan.
- Aplikasi tidak menggunakan AI, Firebase Messaging, Cloud Functions, atau
  dataset eksternal.
