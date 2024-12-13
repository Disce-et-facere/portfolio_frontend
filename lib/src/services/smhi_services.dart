import 'package:http/http.dart' as http;
import 'dart:convert';

class SMHIService {
  final String stockholmLatitude = '59.3293';
  final String stockholmLongitude = '18.0686';

  Future<List<Map<String, dynamic>>> fetchWeeklyWeatherData() async {
    final url =
        'https://opendata-download-metfcst.smhi.se/api/category/pmp3g/version/2/geotype/point/lon/$stockholmLongitude/lat/$stockholmLatitude/data.json';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timeseries = data['timeSeries'];
        return timeseries.map<Map<String, dynamic>>((item) {
          final validTime = item['validTime'];
          final parameters = item['parameters'];
          final temperature = parameters.firstWhere((param) => param['name'] == 't')['values'][0];
          final windSpeed = parameters.firstWhere((param) => param['name'] == 'ws')['values'][0];
          final description = 'Partly Cloudy'; // Placeholder; update based on API
          return {
            'date': validTime,
            'temperature': temperature,
            'windSpeed': windSpeed,
            'description': description,
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }
}