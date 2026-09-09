import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/constants/api_routes.dart';

class AuthService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  Future<Map<String, dynamic>> login(String telephone, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.login}'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'telephone': telephone,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) {
          throw Exception(body['message']);
        }
      } catch (e) {
        if (e.toString().contains('Exception:')) rethrow;
      }
      throw Exception('Les identifiants sont incorrects ou le serveur est inaccessible.');
    }
  }

  Future<Map<String, dynamic>> register(String nom, String prenom, String telephone, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.register}'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) {
          throw Exception(body['message']);
        }
      } catch (e) {
        if (e.toString().contains('Exception:')) rethrow;
      }
      throw Exception('Erreur lors de l\'inscription. Veuillez vérifier vos données.');
    }
  }
}
