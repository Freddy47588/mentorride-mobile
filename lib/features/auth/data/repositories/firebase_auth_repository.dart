import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentorride/core/errors/app_exception.dart';
import 'package:mentorride/core/errors/firebase_error_mapper.dart';
import 'package:mentorride/features/auth/domain/models/auth_session.dart';
import 'package:mentorride/features/auth/domain/models/user_profile.dart';
import 'package:mentorride/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : this._(auth, firestore);

  FirebaseAuthRepository._(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthSession?> authStateChanges() {
    return _auth.authStateChanges().map(_sessionFromUser);
  }

  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) return null;

          return UserProfile.fromMap({
            ...data,
            'uid': snapshot.id,
            'createdAt': _dateTimeFromTimestamp(data['createdAt']),
            'updatedAt': _dateTimeFromTimestamp(data['updatedAt']),
          });
        })
        .handleError((Object error) {
          throw FirebaseErrorMapper.auth(error);
        });
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on Object catch (error) {
      throw FirebaseErrorMapper.auth(error);
    }
  }

  @override
  Future<UserProfile> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final normalizedName = displayName.trim();
    final normalizedEmail = email.trim();
    User? createdUser;
    var profileWritten = false;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'Akun berhasil dibuat, tetapi sesi tidak tersedia.',
        );
      }
      createdUser = user;

      await _firestore.collection('users').doc(user.uid).set({
        'displayName': normalizedName,
        'email': user.email ?? normalizedEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      profileWritten = true;
      await user.updateDisplayName(normalizedName);

      return UserProfile(
        uid: user.uid,
        displayName: normalizedName,
        email: user.email ?? normalizedEmail,
      );
    } on Object catch (error) {
      if (createdUser != null) {
        if (profileWritten) {
          try {
            await _firestore.collection('users').doc(createdUser.uid).delete();
          } on Object {
            // Pembersihan bersifat best-effort; error awal tetap dilaporkan.
          }
        }
        try {
          await createdUser.delete();
        } on Object {
          try {
            await _auth.signOut();
          } on Object {
            // Pembersihan bersifat best-effort; error awal tetap dilaporkan.
          }
        }
      }
      throw FirebaseErrorMapper.auth(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on Object catch (error) {
      throw FirebaseErrorMapper.auth(error);
    }
  }

  @override
  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final normalizedName = displayName.trim();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != uid) {
        throw const AuthFailure(
          'Sesi Anda telah berakhir. Silakan masuk kembali.',
        );
      }

      await _firestore.collection('users').doc(uid).set({
        'displayName': normalizedName,
        'email': currentUser.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await currentUser.updateDisplayName(normalizedName);
    } on Object catch (error) {
      throw FirebaseErrorMapper.auth(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object catch (error) {
      throw FirebaseErrorMapper.auth(error);
    }
  }

  AuthSession? _sessionFromUser(User? user) {
    if (user == null) return null;
    return AuthSession(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      isEmailVerified: user.emailVerified,
    );
  }

  DateTime? _dateTimeFromTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
