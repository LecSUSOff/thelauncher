import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int weatherCode;
  final String city;

  const WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.city,
  });
}

class WeatherService {
  static Future<WeatherData?> fetchCurrentWeather({
    Duration timeout = const Duration(seconds: 7),
  }) async {
    double lat = 52.52;
    double lon = 13.41;
    String city = "Local";

    // Try to get location from IP
    try {
      final locRes = await http.get(
        Uri.parse('https://ipapi.co/json/'),
        headers: {'User-Agent': 'CandyLauncher/1.0'},
      ).timeout(timeout);
      
      if (locRes.statusCode == 200) {
        final locData = json.decode(locRes.body);
        if (locData['latitude'] != null && locData['longitude'] != null) {
          lat = (locData['latitude'] as num).toDouble();
          lon = (locData['longitude'] as num).toDouble();
          city = locData['city'] ?? "Local";
        }
      }
    } catch (_) {}

    // Try to get weather data
    try {
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code',
      );
      final weatherRes = await http.get(weatherUrl).timeout(timeout);

      if (weatherRes.statusCode == 200) {
        final current = json.decode(weatherRes.body)['current'];
        return WeatherData(
          temperature: (current['temperature_2m'] as num).toDouble(),
          weatherCode: current['weather_code'] as int,
          city: city,
        );
      }
    } catch (_) {}

    return null;
  }

  static String getWeatherCondition(int code) {
    if (code == 0) return "Clear Sky";
    if (code <= 3) return "Partly Cloudy";
    if (code <= 48) return "Foggy";
    if (code <= 67) return "Rainy";
    if (code <= 77) return "Snowy";
    if (code <= 82) return "Showers";
    return "Thunderstorm";
  }
}
