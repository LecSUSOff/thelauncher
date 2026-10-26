import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static Future<void> searchTheWeb(String query) async {
    final Uri url = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openWikipedia(String title) async {
    final wikiUrl = Uri.parse(
      'https://en.wikipedia.org/wiki/${Uri.encodeComponent(title)}',
    );
    await launchUrl(wikiUrl, mode: LaunchMode.externalApplication);
  }
}
