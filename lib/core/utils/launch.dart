import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [raw] in the platform default handler. Swallows failures so a missing
/// browser/mail client never crashes the portfolio.
Future<void> openUrl(String raw) async {
  final uri = Uri.parse(raw);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Could not launch $raw: $e');
  }
}
