import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/player_model.dart';
import 'auth_provider.dart';

class PlayerProvider with ChangeNotifier {
  List<Player> _players = [];
  bool _isLoading = false;

  List<Player> get players => _players;
  List<Player> get titulaires => _players.where((p) => p.statutConvocation == 'TITULAIRE').toList();
  List<Player> get remplacants => _players.where((p) => p.statutConvocation == 'REMPLACANT').toList();
  List<Player> get nonRetenus => _players.where((p) => p.statutConvocation == null || p.statutConvocation == 'REPOS').toList();
  bool get isLoading => _isLoading;

  Future<void> fetchPlayers(AuthProvider authProvider) async {
    final token = authProvider.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/players'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _players = data.map((json) => Player.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching players: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> addPlayer(AuthProvider authProvider, String nom, String poste) async {
    final token = authProvider.token;
    if (token == null) return;

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.post(
        Uri.parse('$apiUrl/players'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: json.encode({'nom': nom, 'poste': poste}),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _players.add(Player.fromJson(data));
        notifyListeners();
      } else {
        throw Exception('Erreur serveur : ${response.body}');
      }
    } catch(e) {
      debugPrint('Error adding player: $e');
      rethrow;
    }
  }
}

