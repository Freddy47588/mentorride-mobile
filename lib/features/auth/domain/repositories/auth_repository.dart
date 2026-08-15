import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/domain/models/user_profile.dart';

abstract interface class AuthRepository {
  Stream<AuthSession?> authStateChanges();

  Stream<UserProfile?> watchUserProfile(String uid);

  Future<void> signIn({required String email, required String password});

  Future<UserProfile> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  });

  Future<void> signOut();
}
