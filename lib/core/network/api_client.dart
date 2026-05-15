import 'dart:convert';
import 'package:http/http.dart' as http;
import '../error/exceptions.dart';

class ApiClient {
  final http.Client client;

  ApiClient({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String url) async {
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw const ServerException('API kalit noto\'g\'ri yoki kvota tugagan');
      } else if (response.statusCode == 404) {
        throw const ServerException('Ma\'lumot topilmadi');
      } else {
        throw ServerException('Server xatolik: ${response.statusCode}');
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Tarmoq xatoligi: $e');
    }
  }
}
