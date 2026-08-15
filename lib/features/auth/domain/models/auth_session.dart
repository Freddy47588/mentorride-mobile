class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.isEmailVerified,
    this.displayName,
  });

  final String uid;
  final String email;
  final String? displayName;
  final bool isEmailVerified;

  factory AuthSession.fromMap(Map<String, Object?> map) {
    return AuthSession(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isEmailVerified': isEmailVerified,
    };
  }

  AuthSession copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isEmailVerified,
  }) {
    return AuthSession(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
