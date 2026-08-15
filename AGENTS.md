# Panduan Agent MentorRide

- Target awal adalah Android dengan application ID
  `com.mentorrideapp.mentorride`; UI pengguna wajib berbahasa Indonesia.
- Pertahankan arsitektur feature-first, Riverpod untuk state/dependency
  injection, GoRouter untuk navigasi, dan model Dart tanpa code generation.
- Gunakan konfigurasi `lib/firebase_options.dart` yang dihasilkan FlutterFire.
  Jangan membuat konfigurasi Firebase, UID, akun, email, token, keystore, atau
  kredensial palsu. Jangan menambahkan service-account key.
- Struktur data harus tetap berada di bawah `users/{uid}/vehicles/{vehicleId}`
  dengan subcollection `service_records` dan `service_schedules`.
- Tulis `createdAt` dan `updatedAt` dengan server timestamp serta tangani nilai
  sementara `null`. Simpan Rupiah, kilometer, tahun, dan ID notifikasi sebagai
  integer.
- Perlakukan `currentOdometer` sebagai nilai monoton. Pembaruan cepat dan edit
  kendaraan harus memakai transaksi, menolak nilai yang lebih kecil, serta
  memperlakukan nilai yang sama sebagai tanpa perubahan. Firestore rules juga
  harus menolak write kendaraan yang menurunkan nilai. Riwayat servis hanya
  boleh menaikkan odometer kendaraan.
- Gunakan `ServiceScheduleDueCalculator` sebagai sumber aturan jatuh tempo pada
  dashboard, daftar, dan detail. Perbandingan tanggal mengabaikan jam; hasil
  tanggal dan odometer harus tetap tersedia sebagai dua dimensi terpisah.
  `currentOdometer >= dueOdometer` berarti ambang kilometer sudah terlambat.
- Preset perawatan adalah data referensi lokal. Jangan mengubahnya menjadi
  dataset eksternal atau menyimpan preset sebagai skema Firestore baru.
- Saat membuat jadwal lanjutan dari jadwal yang selesai, hanya gunakan judul dan
  jenis servis sebagai isian awal. Tanggal harus dipilih ulang; kilometer
  opsional dan konfigurasi pengingat tidak boleh diwarisi.
- Notifikasi bersifat lokal, memakai timezone Asia/Jakarta, dan harus konsisten
  pada create, edit, delete, selesai, penghapusan kendaraan, serta logout.
- Notifikasi lokal dipicu oleh `reminderAt`; aplikasi tidak memantau odometer
  fisik di latar belakang. Status kilometer baru berubah setelah odometer atau
  data kendaraan diperbarui, jadi jangan mengklaim notifikasi kilometer waktu
  nyata.
- Firestore rules wajib memeriksa `request.auth.uid == uid`; jangan pernah
  menambahkan akses publik atau sekadar memeriksa pengguna sudah login.
- Jangan menambahkan AI, dataset eksternal, nama pribadi, Firebase Messaging,
  atau Cloud Functions tanpa instruksi eksplisit.
- Sebelum menyerahkan perubahan, jalankan:

  ```bash
  dart format lib test
  flutter analyze
  flutter test
  flutter build apk --debug
  ```

- Jangan memasukkan build output, cache, `.env`, key, token, atau kredensial ke
  Git. Tinjau status dan staged diff sebelum commit; jangan push atau deploy
  tanpa instruksi eksplisit.
