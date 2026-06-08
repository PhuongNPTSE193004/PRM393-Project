class Validators {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');

  static bool isEmail(String value) => _emailRegex.hasMatch(value.trim());

  static bool isPhone(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s\-()]'), '');
    return _phoneRegex.hasMatch(normalized);
  }

  static bool isEmailOrPhone(String value) {
    final trimmed = value.trim();
    return isEmail(trimmed) || isPhone(trimmed);
  }

  static bool isPasswordValid(String value) => value.length >= 6;

  static String? validateIdentifier(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please fill in all required fields.';
    if (!isEmailOrPhone(trimmed)) {
      return 'Please enter a valid email or phone number.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please fill in all required fields.';
    if (!isPasswordValid(password)) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if ((confirm ?? '').isEmpty) return 'Please fill in all required fields.';
    if (password != confirm) return 'Passwords do not match.';
    return null;
  }
}
