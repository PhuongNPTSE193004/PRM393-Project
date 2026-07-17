import 'user_role.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final UserRole role;
  final String? profileImage;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.address = '',
    this.role = UserRole.customer,
    this.profileImage,
    this.createdAt,
  });
}
