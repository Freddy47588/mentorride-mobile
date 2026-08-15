import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentorride/core/firebase/firebase_providers.dart';
import 'package:mentorride/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/domain/models/user_profile.dart';
import 'package:mentorride/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authStateProvider = StreamProvider<AuthSession?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final authSessionProvider = authStateProvider;

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final session = ref.watch(authStateProvider).value;
  if (session == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUserProfile(session.uid);
});
