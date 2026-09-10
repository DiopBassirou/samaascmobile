import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_provider.dart';

class PouleProvider with ChangeNotifier {
  List<dynamic> _poules = [];
  bool _isLoading = false;

  List<dynamic> get poules => _poules;
  bool get isLoading => _isLoading;

  Future<void> fetchPoules(AuthProvider authProvider) async {
    final token = authProvider.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/poules'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _poules = json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching poules: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPoule(AuthProvider authProvider, String nomPoule, List<String> equipes, {String categorie = 'SENIOR'}) async {
    final token = authProvider.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.post(
        Uri.parse('$apiUrl/poules'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'nom': nomPoule,
          'equipes': equipes,
          'categorie': categorie,
        }),
      );

      if (response.statusCode == 201) {
        await fetchPoules(authProvider);
      } else {
        throw Exception('Erreur lors de la création de la poule: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating poule: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitOtherMatchResult(AuthProvider authProvider, int team1Id, int team2Id, int score1, int score2) async {
    final token = authProvider.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.post(
        Uri.parse('$apiUrl/poules/other-match'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'team1_id': team1Id,
          'team2_id': team2Id,
          'score1': score1,
          'score2': score2,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh poules to get updated standings
        await fetchPoules(authProvider);
      } else {
        throw Exception('Erreur lors de la mise à jour du classement: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error submitting other match result: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
