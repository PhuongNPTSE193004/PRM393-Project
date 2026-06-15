abstract class AuthRepository {
  Stream<String?> get authStateChanges;

  String? get currentUserId;

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
