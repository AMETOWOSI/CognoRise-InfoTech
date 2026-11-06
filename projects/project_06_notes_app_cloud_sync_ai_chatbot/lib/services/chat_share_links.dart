class ChatShareLinks {
  const ChatShareLinks._();

  static const host = 'notes-cloud-a9ea8.web.app';

  static Uri forId(String shareId) => Uri.https(host, '/share/$shareId');

  static String? shareIdFromUri(Uri uri) {
    final isWebLink =
        uri.scheme == 'https' &&
        uri.host == host &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'share';
    final isAppLink =
        uri.scheme == 'noteflow' &&
        uri.host == 'share' &&
        uri.pathSegments.length == 1;
    if (!isWebLink && !isAppLink) return null;

    final shareId = isWebLink ? uri.pathSegments[1] : uri.pathSegments[0];
    return RegExp(r'^[A-Za-z0-9_-]{20}$').hasMatch(shareId) ? shareId : null;
  }
}
