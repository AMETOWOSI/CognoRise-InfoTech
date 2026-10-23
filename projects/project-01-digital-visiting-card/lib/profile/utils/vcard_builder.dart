import '../models/profile.dart';
import 'profile_link_utils.dart';

String buildVCard(Profile profile) {
  final nameParts = profile.fullName.trim().split(RegExp(r'\s+'));
  final givenName = nameParts.first;
  final familyName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

  final lines = <String>[
    'BEGIN:VCARD',
    'VERSION:3.0',
    'N:${_escapeVCardText(familyName)};${_escapeVCardText(givenName)};;;',
    'FN:${_escapeVCardText(profile.fullName)}',
  ];

  if (profile.jobTitle.trim().isNotEmpty) {
    lines.add('TITLE:${_escapeVCardText(profile.jobTitle.trim())}');
  }
  if (profile.company.trim().isNotEmpty) {
    lines.add('ORG:${_escapeVCardText(profile.company.trim())}');
  }
  if (profile.phone.trim().isNotEmpty) {
    lines.add('TEL;TYPE=CELL:${_escapeVCardText(profile.phone.trim())}');
  }
  if (profile.email.trim().isNotEmpty) {
    lines.add('EMAIL;TYPE=INTERNET:${_escapeVCardText(profile.email.trim())}');
  }
  if (profile.location.trim().isNotEmpty) {
    lines.add(
      'ADR;TYPE=WORK:;;${_escapeVCardText(profile.location.trim())};;;;',
    );
  }
  if (profile.bio.trim().isNotEmpty) {
    lines.add('NOTE:${_escapeVCardText(profile.bio.trim())}');
  }

  final urls = [
    profile.portfolioUrl,
    profile.linkedinUrl,
    profile.facebookUrl,
    profile.instagramUrl,
  ];
  for (final url in urls) {
    final uri = profileWebUri(url);
    if (uri != null) {
      lines.add('URL:${uri.toString()}');
    }
  }

  lines.add('END:VCARD');
  return lines.join('\r\n');
}

String _escapeVCardText(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\r\n', r'\n')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\n');
}
