import 'dart:convert';
import 'package:http/http.dart' as http;

class WikiDefinition {
  final String title;
  final String summary;
  final String? thumbnailUrl;

  WikiDefinition({required this.title, required this.summary, this.thumbnailUrl});
}

Future<WikiDefinition?> fetchDefinition(String query) async {
  final cleanQuery = query.trim();
  if (cleanQuery.length < 3) return null;

  try {
    // 1. Ask OpenSearch for the best predictive article title (Case-insensitive!)
    final searchUrl = Uri.parse(
      'https://en.wikipedia.org/w/api.php?action=opensearch&search=${Uri.encodeComponent(cleanQuery)}&limit=1&format=json',
    );
    final searchRes = await http.get(searchUrl);
    
    if (searchRes.statusCode != 200) return null;
    
    // OpenSearch returns an array where index [1] contains the matching titles
    final List titles = json.decode(searchRes.body)[1];
    if (titles.isEmpty) return null; // No matching articles found

    final String exactTitle = titles.first; // e.g., "Python (programming language)"

    // 2. Fetch the rich summary using the resolved title
    final summaryUrl = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(exactTitle)}',
    );
    final response = await http.get(summaryUrl, headers: {
      'User-Agent': 'CandyLauncher/1.0 (candylauncher@example.com)',
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WikiDefinition(
        title: data['title'] ?? exactTitle,
        summary: data['extract'] ?? '',
        thumbnailUrl: data['thumbnail']?['source'],
      );
    }
  } catch (e) {
    print("Wiki Error: $e");
    return null;
  }
  return null;
}