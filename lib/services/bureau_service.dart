import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BureauService {
  final String _baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';

  Future<List<dynamic>> fetchBureau(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/bureau'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erreur lors du chargement du bureau');
    }
  }

  Future<List<dynamic>> searchUsers(String token, String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/bureau/search?q=$query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erreur lors de la recherche des utilisateurs');
    }
  }

  Future<Map<String, dynamic>> assignRole(String token, String search, int roleId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/bureau/assign'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'search': search,
        'role_id': roleId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final body = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(body['message'] ?? 'Erreur lors de l\'assignation du rôle');
    }
  }
}
