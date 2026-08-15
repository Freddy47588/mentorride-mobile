import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/errors/firebase_error_mapper.dart';
import 'package:mentorride/features/auth/domain/repositories/auth_repository.dart';
import 'package:mentorride/features/auth/providers/auth_repository_provider.dart';

class AuthActionState {
  const AuthActionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  AuthActionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class AuthController extends Notifier<AuthActionState> {
  late final AuthRepository _repository;

  @override
  AuthActionState build() {
    _repository = ref.watch(authRepositoryProvider);
    return const AuthActionState();
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
  }) {
    return _run(() async {
      await _repository.register(
        displayName: displayName,
        email: email,
        password: password,
      );
    });
  }

  Future<bool> sendPasswordResetEmail(String email) {
    return _run(
      () => _repository.sendPasswordResetEmail(email),
      successMessage:
          'Tautan atur ulang kata sandi telah dikirim ke email Anda.',
    );
  }

  Future<bool> signOut() => _run(_repository.signOut);

  void clearFeedback() {
    if (state.errorMessage == null && state.successMessage == null) return;
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<bool> _run(
    Future<void> Function() operation, {
    String? successMessage,
  }) async {
    if (state.isSubmitting) return false;

    state = const AuthActionState(isSubmitting: true);
    try {
      await operation();
      state = AuthActionState(successMessage: successMessage);
      return true;
    } on Object catch (error) {
      state = AuthActionState(
        errorMessage: FirebaseErrorMapper.auth(error).message,
      );
      return false;
    }
  }
}
