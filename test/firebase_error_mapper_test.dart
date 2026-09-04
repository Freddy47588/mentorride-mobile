import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/core/errors/firebase_error_mapper.dart';

void main() {
  test('auth token kedaluwarsa dipetakan ke pesan sesi Indonesia', () {
    for (final code in [
      'user-token-expired',
      'invalid-user-token',
      'session-cookie-expired',
    ]) {
      final failure = FirebaseErrorMapper.auth(
        FirebaseAuthException(code: code),
      );

      expect(
        failure.message,
        'Sesi Anda telah berakhir. Silakan masuk kembali.',
      );
      expect(failure.message, isNot(contains(code)));
    }
  });
}
