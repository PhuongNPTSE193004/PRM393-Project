import '../models/user_role.dart';

abstract class UserRepository {
  Future<UserRole?> getUserRole(String uid);

  Future<String?> findEmailByPhone(String phone);

  Future<bool> accountExistsByEmail(String email);

  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? phone,
    UserRole role,
    String? displayName,
  });
}
