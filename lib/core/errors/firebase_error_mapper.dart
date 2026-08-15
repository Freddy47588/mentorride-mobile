import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentorride/core/errors/app_exception.dart';

abstract final class FirebaseErrorMapper {
  static AuthFailure auth(Object error) {
    if (error is AuthFailure) return error;

    if (error is FirebaseAuthException) {
      return AuthFailure(_authMessage(error.code), code: error.code);
    }

    if (error is FirebaseException) {
      return AuthFailure(_firebaseMessage(error.code), code: error.code);
    }

    return const AuthFailure(
      'Terjadi kesalahan. Silakan coba lagi beberapa saat lagi.',
    );
  }

  static String _authMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Format email tidak valid.',
      'user-disabled' => 'Akun ini telah dinonaktifkan.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email atau kata sandi tidak sesuai.',
      'email-already-in-use' => 'Email ini sudah digunakan oleh akun lain.',
      'weak-password' =>
        'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.',
      'operation-not-allowed' => 'Metode masuk dengan email belum diaktifkan.',
      'too-many-requests' =>
        'Terlalu banyak percobaan. Silakan coba lagi nanti.',
      'network-request-failed' =>
        'Tidak dapat terhubung. Periksa koneksi internet Anda.',
      'requires-recent-login' =>
        'Silakan masuk kembali untuk melanjutkan perubahan ini.',
      'account-exists-with-different-credential' =>
        'Email ini sudah terdaftar dengan metode masuk lain.',
      'credential-already-in-use' =>
        'Kredensial ini sudah digunakan oleh akun lain.',
      'expired-action-code' => 'Tautan tindakan sudah kedaluwarsa.',
      'invalid-action-code' => 'Tautan tindakan tidak valid.',
      'missing-email' => 'Email wajib diisi.',
      _ => 'Autentikasi gagal. Silakan coba lagi.',
    };
  }

  static String _firebaseMessage(String code) {
    return switch (code) {
      'permission-denied' =>
        'Anda tidak memiliki izin untuk melakukan tindakan ini.',
      'unavailable' || 'deadline-exceeded' =>
        'Layanan sedang tidak tersedia. Silakan coba lagi nanti.',
      'cancelled' => 'Permintaan dibatalkan.',
      _ => 'Layanan Firebase mengalami kendala. Silakan coba lagi.',
    };
  }
}
