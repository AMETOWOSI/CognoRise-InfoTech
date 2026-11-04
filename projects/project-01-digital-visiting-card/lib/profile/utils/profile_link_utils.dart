bool isValidEmailAddress(String value) {
  final email = value.trim();
  if (email.isEmpty || email.length > 254) return false;

  final atIndex = email.indexOf('@');
  if (atIndex <= 0 || atIndex != email.lastIndexOf('@')) return false;

  final localPart = email.substring(0, atIndex);
  final domain = email.substring(atIndex + 1);
  if (localPart.length > 64 || domain.length > 253) return false;

  final localPartPattern = RegExp(r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+$");
  if (localPart.split('.').any((part) => !localPartPattern.hasMatch(part))) {
    return false;
  }

  final domainLabels = domain.split('.');
  final domainLabelPattern = RegExp(
    r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$',
  );
  return domainLabels.length > 1 &&
      domainLabels.every(
        (label) => label.length <= 63 && domainLabelPattern.hasMatch(label),
      );
}

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
