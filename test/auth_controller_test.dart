import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/domain/models/user_profile.dart';
import 'package:mentorride/features/auth/domain/repositories/auth_repository.dart';
import 'package:mentorride/features/auth/providers/auth_providers.dart';

void main() {
  test('AuthController mencegah submit login ganda', () async {
    final repository = _DelayedAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);

    final firstResult = controller.signIn(
      email: 'rider@mentorride.id',
      password: 'rahasia',
    );

    expect(container.read(authControllerProvider).isSubmitting, isTrue);
    expect(repository.signInCalls, 1);

    final secondResult = await controller.signIn(
      email: 'rider@mentorride.id',
      password: 'rahasia',
    );

    expect(secondResult, isFalse);
    expect(repository.signInCalls, 1);

    repository.completeSignIn();
    expect(await firstResult, isTrue);
    expect(container.read(authControllerProvider).isSubmitting, isFalse);
    expect(container.read(authControllerProvider).errorMessage, isNull);
  });
}

class _DelayedAuthRepository implements AuthRepository {
  final Completer<void> _signInCompleter = Completer<void>();

  int signInCalls = 0;

  void completeSignIn() => _signInCompleter.complete();

  @override
  Stream<AuthSession?> authStateChanges() => const Stream.empty();

  @override
  Future<UserProfile> register({
    required String displayName,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    signInCalls += 1;
    return _signInCompleter.future;
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<UserProfile?> watchUserProfile(String uid) => const Stream.empty();
}
