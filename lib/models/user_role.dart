enum UserRole {
  admin,
  staff,
  customer;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.customer;
    }
  }

  String get firestoreValue => name;
}
