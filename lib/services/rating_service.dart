import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  final String _baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<dynamic>> getMatches() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/matches'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erreur de chargement des matchs');
    }
  }

  // Simule la récupération des joueurs du match, car l'API complète n'expose pas encore l'effectif convoqué par match publiquement
  Future<List<dynamic>> getPlayersForMatch(int matchId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/players'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erreur de chargement des joueurs');
    }
  }

  Future<void> submitRating(int matchId, int playerId, int note) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/matches/$matchId/players/$playerId/rate'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'note': note}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur lors du vote');
    }
  }
}
