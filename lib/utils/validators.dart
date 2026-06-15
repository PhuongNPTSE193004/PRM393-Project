class Validators {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
  static final _uppercaseRegex = RegExp(r'[A-Z]');
  static final _symbolRegex = RegExp(r'[^a-zA-Z0-9\s]');

  static const loginPasswordError = 'Invalid email or password.';
  static const registerPasswordError =
      'Password must be at least 6 characters and include an uppercase letter and a symbol.';

  static bool isEmail(String value) => _emailRegex.hasMatch(value.trim());

  static bool isPhone(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s\-()]'), '');
    return _phoneRegex.hasMatch(normalized);
  }

  static bool isEmailOrPhone(String value) {
    final trimmed = value.trim();
    return isEmail(trimmed) || isPhone(trimmed);
  }

  static bool hasUppercase(String value) => _uppercaseRegex.hasMatch(value);

  static bool hasSymbol(String value) => _symbolRegex.hasMatch(value);

  static bool isLoginPasswordValid(String value) => value.length >= 6;

  static bool isRegisterPasswordValid(String value) {
    return value.length >= 6 && hasUppercase(value) && hasSymbol(value);
  }

  static String? validateIdentifier(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please fill in all required fields.';
    if (!isEmailOrPhone(trimmed)) {
      return 'Please enter a valid email or phone number.';
    }
    return null;
  }

  static String? validateLoginPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please fill in all required fields.';
    if (!isLoginPasswordValid(password)) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? validateRegisterPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please fill in all required fields.';
    if (!isRegisterPasswordValid(password)) {
      return registerPasswordError;
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if ((confirm ?? '').isEmpty) return 'Please fill in all required fields.';
    if (password != confirm) return 'Passwords do not match.';
    return null;
  }
}
