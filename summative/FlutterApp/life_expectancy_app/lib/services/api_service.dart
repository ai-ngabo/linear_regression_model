import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://linear-regression-model-d6zo.onrender.com';

  Future<double> predict(Map<String, dynamic> features) async {
    final uri = Uri.parse('$baseUrl/predict');

    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(features),
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException {
      throw Exception('Network error. Please check your connection.');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['predicted_life_expectancy_years'] as num).toDouble();
    } else if (response.statusCode == 422) {
      final data = jsonDecode(response.body);
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        final msg = detail[0]['msg'] ?? 'Validation error';
        throw Exception('Invalid input: $msg');
      }
      throw Exception('Validation error: values may be out of range.');
    } else if (response.statusCode == 500) {
      throw Exception('Server error. Please try again later.');
    } else {
      throw Exception('Unexpected error (${response.statusCode}).');
    }
  }
}