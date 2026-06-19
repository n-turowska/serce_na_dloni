import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiClient {
  final String baseUrl;

  ApiClient({this.baseUrl = apiBaseUrl});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tempAuthToken',
      };

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    // Make the GET request and handle the response
    final response = await http.get(url, headers: _headers);
    if (response.statusCode >= 200 && response.statusCode < 300){
      return jsonDecode(response.body);
    }
    throw ApiException(
      'GET $endpoint failed',
      statusCode: response.statusCode,
    );
  }


}