Uri? profileWebUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

Uri? whatsappUri(String phoneNumber) {
  final normalized = phoneNumber.trim();
  final digits = normalized.replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'^\+[0-9(). -]+$').hasMatch(normalized) ||
      digits.length < 8 ||
      digits.length > 15) {
    return null;
  }
  return Uri.https('wa.me', '/$digits');
}
