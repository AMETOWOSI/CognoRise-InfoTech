import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchExternalLink(BuildContext context, Uri uri) async {
  try {
    final didLaunch = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!didLaunch && context.mounted) {
      _showLaunchError(context, 'No app could open this link.');
    }
  } on PlatformException catch (error) {
    if (!context.mounted) return;
    _showLaunchError(context, 'Could not open this link: ${error.message}');
  }
}

void _showLaunchError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
