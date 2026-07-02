abstract class AuthRepository {
  Stream<String?> get authStateChanges;

  String? get currentUserId;

  String? get currentUserEmail;

  bool get isEmailVerified;

  Future<void> reloadCurrentUser();

  Future<void> sendEmailVerification();

  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<String> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);
}
