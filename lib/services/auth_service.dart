import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_exception.dart';
import '../models/user_role.dart';
import '../repositories/auth_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firestore_user_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/validators.dart';

class AuthService {
  AuthService({
    AuthRepository? authRepository,
    UserRepository? userRepository,
  })  : _authRepository = authRepository ?? FirebaseAuthRepository(),
        _userRepository = userRepository ?? FirestoreUserRepository();

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Stream<String?> get authStateChanges => _authRepository.authStateChanges;

  String? get currentUserId => _authRepository.currentUserId;

  Future<UserRole?> getCurrentUserRole() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return _userRepository.getUserRole(uid);
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

    if (!Validators.isLoginPasswordValid(trimmedPassword)) {
      throw AuthException(Validators.loginPasswordError);
    }

    String email;
    if (Validators.isEmail(trimmedIdentifier)) {
      email = trimmedIdentifier.toLowerCase();
    } else {
      final foundEmail =
          await _userRepository.findEmailByPhone(trimmedIdentifier);
      if (foundEmail == null) {
        throw AuthException(Validators.loginPasswordError);
      }
      email = foundEmail;
    }

    try {
      final uid = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: trimmedPassword,
      );

      final role = await _userRepository.getUserRole(uid);
      if (role == null) {
        await _authRepository.signOut();
        throw AuthException(Validators.loginPasswordError);
      }

      return role;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e, isLogin: true));
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

    if (!Validators.isRegisterPasswordValid(trimmedPassword)) {
      throw AuthException(Validators.registerPasswordError);
    }

    try {
      final uid = await _authRepository.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      await _userRepository.createUserProfile(
        uid: uid,
        email: trimmedEmail,
        phone: trimmedPhone,
        displayName: displayName,
      );

      return UserRole.customer;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e, isLogin: false));
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
          await _userRepository.findEmailByPhone(trimmedIdentifier);
      if (foundEmail == null) {
        throw AuthException('Account does not exist.');
      }
      email = foundEmail;
    } else {
      throw AuthException('Please enter a valid email or phone number.');
    }

    try {
      await _authRepository.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e, isLogin: true));
    }
  }

  Future<void> logout() => _authRepository.signOut();

  String _mapFirebaseAuthError(FirebaseAuthException e, {bool isLogin = true}) {
    switch (e.code) {
      case 'invalid-email':
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return Validators.loginPasswordError;
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return isLogin
            ? Validators.loginPasswordError
            : Validators.registerPasswordError;
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return Validators.loginPasswordError;
    }
  }
}
