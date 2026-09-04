# MentorRide Mobile

MentorRide adalah aplikasi Android untuk mencatat kendaraan, riwayat servis,
biaya perawatan, jadwal servis, dan pengingat lokal. Seluruh data berasal dari
input pengguna dan disimpan per akun di Cloud Firestore.

## Fitur

- Registrasi, login, reset kata sandi, edit nama, dan logout dengan Firebase
  Authentication.
- Onboarding tiga langkah pada penggunaan pertama. Status selesai disimpan
  lokal dengan `shared_preferences`, bukan di Firestore.
- CRUD kendaraan, pilihan kendaraan aktif yang disimpan per pengguna, dan
  pembaruan odometer cepat. Nilai odometer dijaga tidak pernah turun melalui
  transaksi Firestore; nilai yang sama diperlakukan sebagai tanpa perubahan.
- Riwayat servis dengan beberapa item per transaksi, total biaya otomatis,
  pencarian lokal berdasarkan bengkel, komponen, dan catatan, filter periode
  dan biaya, serta pembaruan odometer kendaraan secara transaksional.
- Statistik perawatan dihitung lokal dari data yang sudah dimuat, meliputi
  jumlah servis, total dan rata-rata biaya, serta komponen yang paling sering
  dirawat.
- Laporan kendaraan aktif dapat diekspor sebagai PDF A4 atau CSV UTF-8 lalu
  dibagikan melalui Android share sheet tanpa izin penyimpanan lama.
- Preset perawatan lokal untuk membantu mengisi komponen dan jenis servis tanpa
  mengambil dataset eksternal.
- Jadwal servis dengan tanggal jatuh tempo dan kilometer jatuh tempo opsional,
  kalkulator status bersama untuk kedua dimensi, pengingat lokal, status
  selesai, dan ID notifikasi yang stabil.
- Alur selesai dapat membuka formulir jadwal berikutnya dengan judul dan jenis
  servis yang sama. Tanggal wajib dipilih ulang; kilometer opsional dan pilihan
  pengingat tidak diwarisi.
- Dashboard kendaraan aktif, servis terakhir, jadwal terdekat, biaya bulan dan
  tahun berjalan, serta grafik biaya enam bulan.
- Antarmuka Material 3 berbahasa Indonesia dengan loading, error, empty state,
  validasi formulir, snackbar, dialog konfirmasi, dan animasi ringan yang
  menghormati pengaturan pengurangan gerakan perangkat.

## Teknologi

- Flutter 3.44 atau lebih baru dan Dart 3.12 atau lebih baru
- Material 3 dan `flutter_localizations`
- Riverpod tanpa code generation
- GoRouter dengan redirect autentikasi
- Firebase Core, Authentication, dan Cloud Firestore
- `flutter_local_notifications` dan `timezone` untuk Asia/Jakarta
- `shared_preferences`, `uuid`, `intl`, dan `fl_chart`
- `pdf`, `path_provider`, dan `share_plus` untuk membuat, menyimpan sementara,
  dan membagikan laporan servis di perangkat

## Struktur folder

```text
lib/
├── app/                         tema, router, dan root aplikasi
├── core/                        Firebase, error, notifikasi, storage, utilitas
├── features/
│   ├── auth/                    autentikasi dan profil pengguna
│   ├── dashboard/               agregasi dan tampilan beranda
│   ├── navigation/              shell bottom navigation
│   ├── onboarding/              pengalaman penggunaan pertama
│   ├── profile/                 profil, izin notifikasi, dan logout
│   ├── service_records/         riwayat servis dan biaya
│   ├── service_reports/         pemetaan dan ekspor laporan kendaraan
│   ├── service_schedules/       jadwal dan pengingat lokal
│   └── vehicles/                kendaraan dan pilihan aktif
├── shared/                      widget yang digunakan lintas fitur
├── firebase_options.dart        konfigurasi klien hasil FlutterFire
└── main.dart                    bootstrap Firebase dan notifikasi
```

Setiap fitur memisahkan model/domain, adapter data atau repository, provider,
controller/service bila diperlukan, dan layar presentasi. Model menggunakan
`fromMap`, `toMap`, dan `copyWith` tanpa code generation. Status jatuh tempo
tanggal dan odometer dihitung oleh satu kalkulator domain agar dashboard,
daftar, dan detail menggunakan aturan yang sama.

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

Pengingat lokal dijadwalkan berdasarkan `reminderAt`, bukan berdasarkan sensor
odometer kendaraan. Ambang `dueOdometer` dievaluasi setelah kilometer kendaraan
diubah atau data terbaru dimuat di aplikasi. Karena MVP tidak memantau kendaraan
di latar belakang, tercapainya kilometer fisik tidak dapat memicu notifikasi
sampai data odometer di aplikasi diperbarui.

## Firestore Security Rules

`firestore.rules` hanya mengizinkan pengguna terautentikasi mengakses profil,
kendaraan, riwayat servis, dan jadwal di bawah `users/{uid}` miliknya. Semua path
lain ditolak. Query saat ini tidak memerlukan compound index, sehingga
`firestore.indexes.json` tetap kosong.

Write dokumen kendaraan juga mewajibkan `currentOdometer` berupa integer
nonnegatif dan tidak lebih kecil daripada nilai yang sudah tersimpan. Dokumen
lama dengan odometer hilang atau bukan integer tetap dapat dimigrasikan ke nilai
valid tanpa membuka akses lintas pengguna.

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
notifikasi diuji melalui fake yang berada di folder `test/`. Kalkulator jatuh
tempo, aturan odometer tidak menurun, preset lokal, dan isian awal jadwal
berikutnya juga memiliki pengujian terpisah. Onboarding, pencarian dan filter,
agregasi statistik, serialisasi CSV, pemetaan dan pembuatan PDF, sanitasi nama
file, keamanan scope ekspor, serta layout pada layar kecil dan teks besar ikut
tercakup.

## GitHub Actions

Workflow [`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)
berjalan untuk setiap push dan pull request ke `main`. CI menggunakan Flutter
3.44.2 dan Java 17, memakai cache Flutter/Pub serta Gradle, lalu menjalankan
instalasi dependency, pemeriksaan format, analyzer, seluruh test, dan build APK
debug. Workflow ini tidak melakukan deploy Firebase atau membuat release.

## Build APK release

Jalankan rangkaian validasi dan build berikut dari root repository:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Konfigurasi Gradle tidak memakai debug key untuk varian release. Sebelum
menjalankan perintah build release, buat keystore milik developer di lokasi
aman di luar repository, lalu buat `android/key.properties` lokal dengan empat
properti `storeFile`, `storePassword`, `keyAlias`, dan `keyPassword`.
`storeFile` harus menunjuk ke keystore sebenarnya. Tanpa file ini, konfigurasi
release tidak memiliki signing config dan artefaknya tidak siap
didistribusikan. File properti dan seluruh format keystore terkait sudah
diabaikan Git dan tidak boleh di-commit.

Setelah signing tersedia, APK release dihasilkan di
`build/app/outputs/flutter-apk/app-release.apk`.

Naikkan `version` pada `pubspec.yaml` sesuai rilis sebelum mengunggah artefak.
Simpan keystore dan password pada password manager atau secret storage tim;
kehilangan upload key dapat menghambat pembaruan aplikasi berikutnya.

## Catatan pengembangan

- Platform awal adalah Android dan seluruh teks pengguna harus berbahasa
  Indonesia.
- Firestore tidak menghapus subcollection secara otomatis; penghapusan
  kendaraan menggunakan cascade delete dan membatalkan pengingat turunannya.
- Odometer kendaraan bersifat monoton: pembaruan cepat, edit kendaraan, dan
  pencatatan servis tidak boleh menurunkan nilai yang sudah tersimpan.
- Mengedit atau menghapus riwayat servis tidak menghitung mundur odometer
  kendaraan.
- Aplikasi tidak menggunakan AI, Firebase Messaging, Cloud Functions, atau
  dataset eksternal.
