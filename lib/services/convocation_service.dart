import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConvocationService {
  final String? baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';

  Future<List<dynamic>> getPlayers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sportif/convocations'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erreur lors de la récupération des joueurs");
    }
  }

  Future<Map<String, dynamic>> submitConvocations(String token, int matchId, List<Map<String, dynamic>> playersData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matches/$matchId/convocations'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'players': playersData,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Erreur de validation de l'effectif");
    }
  }
}
