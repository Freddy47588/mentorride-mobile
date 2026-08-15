class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AuthFailure extends AppException {
  const AuthFailure(super.message, {super.code});
}

String userFacingErrorMessage(Object error, {required String fallback}) {
  if (error is AppException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return fallback;
}
