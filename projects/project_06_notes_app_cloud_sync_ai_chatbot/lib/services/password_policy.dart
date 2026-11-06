String? validateStrongPassword(String? value) {
  if (value == null || value.length < 8) {
    return 'Use at least 8 characters.';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Include at least one uppercase letter.';
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Include at least one lowercase letter.';
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Include at least one number.';
  }
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    return 'Include at least one symbol.';
  }
  return null;
}
