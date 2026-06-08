import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role.dart';
import '../utils/validators.dart';
import 'user_service.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({UserService? userService})
      : _userService = userService ?? UserService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserRole?> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) return null;
    return _userService.getUserRole(user.uid);
  }

  Future<UserRole> login({
    required String identifier,
    required String password,
  }) async {
    final trimmedIdentifier = identifier.trim();
    final trimmedPassword = password;

    if (trimmedIdentifier.isEmpty || trimmedPassword.isEmpty) {
      throw AuthException('Please fill in all required fields.');
    }

    if (!Validators.isEmailOrPhone(trimmedIdentifier)) {
      throw AuthException('Please enter a valid email or phone number.');
    }

    if (!Validators.isPasswordValid(trimmedPassword)) {
      throw AuthException('Password must be at least 6 characters.');
    }

    String email;
    if (Validators.isEmail(trimmedIdentifier)) {
      email = trimmedIdentifier.toLowerCase();
    } else {
      final foundEmail =
          await _userService.findEmailByPhone(trimmedIdentifier);
      if (foundEmail == null) {
        throw AuthException('Account does not exist.');
      }
      email = foundEmail;
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: trimmedPassword,
      );

      final role = await _userService.getUserRole(credential.user!.uid);
      if (role == null) {
        await _auth.signOut();
        throw AuthException('Account does not exist.');
      }

      return role;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  Future<UserRole> register({
    required String email,
    required String password,
    String? phone,
    String? displayName,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password;
    final trimmedPhone = phone?.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      throw AuthException('Please fill in all required fields.');
    }

    if (!Validators.isEmail(trimmedEmail)) {
      throw AuthException('Please enter a valid email or phone number.');
    }

    if (trimmedPhone != null &&
        trimmedPhone.isNotEmpty &&
        !Validators.isPhone(trimmedPhone)) {
      throw AuthException('Please enter a valid email or phone number.');
    }

    if (!Validators.isPasswordValid(trimmedPassword)) {
      throw AuthException('Password must be at least 6 characters.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      await _userService.createUserProfile(
        uid: credential.user!.uid,
        email: trimmedEmail,
        phone: trimmedPhone,
        displayName: displayName,
      );

      return UserRole.customer;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  Future<void> sendPasswordReset(String identifier) async {
    final trimmedIdentifier = identifier.trim();

    if (trimmedIdentifier.isEmpty) {
      throw AuthException('Please fill in all required fields.');
    }

    String email;
    if (Validators.isEmail(trimmedIdentifier)) {
      email = trimmedIdentifier.toLowerCase();
    } else if (Validators.isPhone(trimmedIdentifier)) {
      final foundEmail =
          await _userService.findEmailByPhone(trimmedIdentifier);
      if (foundEmail == null) {
        throw AuthException('Account does not exist.');
      }
      email = foundEmail;
    } else {
      throw AuthException('Please enter a valid email or phone number.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-not-found':
        return 'Account does not exist.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Invalid email or password.';
    }
  }
}
