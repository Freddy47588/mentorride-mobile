# Checklist Rilis MentorRide v1.0.0

Checklist ini harus dijalankan pada commit rilis final. Beri tanda centang hanya
setelah langkah benar-benar diverifikasi.

## Validasi otomatis

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build apk --debug`
- [ ] GitHub Actions pada commit rilis berstatus hijau

## Signing dan APK release

- [ ] Keystore release tersimpan aman di luar repository
- [ ] `android/key.properties` tersedia secara lokal dan lengkap
- [ ] `storeFile` menunjuk ke keystore yang benar
- [ ] `key.properties`, password, dan keystore tidak masuk Git
- [ ] `flutter build apk --release` berhasil
- [ ] `build/app/outputs/flutter-apk/app-release.apk` tersedia
- [ ] Salinan artefak diberi nama `MentorRide-v1.0.0.apk`

Contoh struktur `android/key.properties` (isi dengan nilai developer sendiri):

```properties
storeFile=C:/lokasi-aman/upload-keystore.jks
storePassword=<password-keystore>
keyAlias=<alias-key>
keyPassword=<password-key>
```

Jangan menyimpan file atau nilai tersebut di repository.

## QA perangkat Android nyata

### Instalasi

- [ ] Fresh install berhasil
- [ ] Aplikasi dapat dibuka
- [ ] Logo dan splash tampil benar

### Autentikasi

- [ ] Registrasi berhasil
- [ ] Login berhasil
- [ ] Reset kata sandi berhasil
- [ ] Logout membatalkan notifikasi dan membersihkan state sesi
- [ ] Pergantian akun tidak menampilkan data akun sebelumnya

### Kendaraan

- [ ] Tambah kendaraan
- [ ] Edit kendaraan
- [ ] Arsip kendaraan aktif dan nonaktif
- [ ] Pulihkan kendaraan arsip
- [ ] Hapus permanen kendaraan arsip
- [ ] Kondisi tanpa kendaraan dan semua kendaraan diarsipkan

### Servis

- [ ] Tambah, edit, dan hapus catatan servis
- [ ] Banyak item, biaya nol, Unicode, dan catatan panjang
- [ ] Pencarian, filter, daftar, dan timeline
- [ ] Odometer sama tidak membuat log
- [ ] Odometer lebih rendah tidak menurunkan kilometer kendaraan

### Odometer

- [ ] Pembaruan naik berhasil dan membuat satu log
- [ ] Nilai sama menjadi no-op tanpa log
- [ ] Nilai turun ditolak
- [ ] Riwayat, periode, statistik, dan grafik tampil benar

### Jadwal dan notifikasi

- [ ] Tambah dan edit jadwal
- [ ] Izin notifikasi diberikan dan ditolak
- [ ] Aktif/nonaktif pengingat
- [ ] Edit tidak meninggalkan reminder lama atau duplikat
- [ ] Hapus dan selesai membatalkan reminder
- [ ] Jadwal berikutnya hanya mewarisi judul dan jenis servis
- [ ] Status Aman, Mendekati, Jatuh tempo, Terlambat, dan Selesai konsisten

### Kondisi Perawatan dan kalender

- [ ] Ringkasan tanpa riwayat dan dengan riwayat parsial
- [ ] Ambang waktu, kilometer, dan gabungan
- [ ] Persentase hanya memakai item dengan data valid
- [ ] Kalender tanpa jadwal, satu jadwal, dan banyak jadwal pada hari sama
- [ ] Perpindahan bulan dan tanggal Asia/Jakarta tidak bergeser sehari

### Laporan dan data

- [ ] PDF kosong, multi-halaman, Unicode, serta teks panjang
- [ ] CSV menangani koma, quote, newline, formula, dan UTF-8
- [ ] Android share sheet terbuka untuk PDF/CSV
- [ ] Backup akun kosong, satu kendaraan, banyak kendaraan, dan arsip
- [ ] Restore file valid berhasil tanpa menghapus data lama
- [ ] Restore JSON rusak, versi tidak didukung, dan angka invalid ditolak
- [ ] Restore banyak data tidak meninggalkan hasil parsial saat batch gagal

### Tampilan dan aksesibilitas

- [ ] Tema Sistem, Terang, dan Gelap
- [ ] Layar sekitar 360x640 logical pixel
- [ ] Font scaling tinggi tanpa overflow
- [ ] Keyboard tidak menutup field penting
- [ ] Tooltip/semantics dan touch target dapat digunakan
- [ ] Reduce motion perangkat dihormati

## Firebase

- [ ] Project Firebase aktif sudah diperiksa oleh developer
- [ ] Rules dan indexes ditinjau sebelum deploy
- [ ] Deploy manual dijalankan bila diperlukan:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Repository ini tidak melakukan deploy Firebase otomatis.

## GitHub Release

- [ ] Target branch `main`
- [ ] Tag `v1.0.0`
- [ ] Judul `MentorRide v1.0.0`
- [ ] Release notes memakai `RELEASE_NOTES.md`
- [ ] APK diunggah sebagai `MentorRide-v1.0.0.apk`
- [ ] Release dipublikasikan manual setelah seluruh checklist lulus
