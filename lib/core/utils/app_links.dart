import 'package:url_launcher/url_launcher.dart';

/// Parent company website.
const appexWebsite = 'https://www.appexbusiness.com';

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Silently ignore if no browser is available.
  }
}
