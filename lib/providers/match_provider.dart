import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/match_model.dart';
import 'auth_provider.dart';

class MatchProvider with ChangeNotifier {
  List<MatchGame> _matches = [];
  bool _isLoading = false;

  List<MatchGame> get matches => _matches;

  /// Match en direct : EN_COURS ou MI_TEMPS (le plus récent)
  MatchGame? get currentMatch {
    final liveMatches = _matches.where((m) => m.statut == 'EN_COURS' || m.statut == 'MI_TEMPS').toList();
    if (liveMatches.isEmpty) return null;
    liveMatches.sort((a, b) => b.dateMatch.compareTo(a.dateMatch));
    return liveMatches.first;
  }

  /// Prochain match programmé (le plus proche)
  MatchGame? get nextMatch {
    final futureMatches = _matches.where((m) => m.statut == 'A_VENIR').toList();
    if (futureMatches.isEmpty) return null;
    futureMatches.sort((a, b) => a.dateMatch.compareTo(b.dateMatch));
    return futureMatches.first;
  }

  /// Dernier match terminé (le plus récent par date)
  MatchGame? get lastMatch {
    final finished = _matches.where((m) => m.statut == 'TERMINE').toList();
    if (finished.isEmpty) return null;
    finished.sort((a, b) => b.dateMatch.compareTo(a.dateMatch));
    return finished.first;
  }

  bool get isLoading => _isLoading;

  Future<void> fetchMatches([AuthProvider? authProvider, String? ascCode]) async {
    final token = authProvider?.token;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final uri = Uri.parse('$apiUrl/matches').replace(
        queryParameters: (ascCode != null && ascCode.isNotEmpty) ? {'asc_code': ascCode} : null,
      );

      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _matches = data.map((json) => MatchGame.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching matches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateScore(AuthProvider authProvider, int matchId, int scoreAsc, int scoreAdv) async {
    final token = authProvider.token;
    if (token == null) return;

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.put(
        Uri.parse('$apiUrl/matches/$matchId/score'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'score_asc': scoreAsc,
          'score_adv': scoreAdv,
        }),
      );

      if (response.statusCode == 200) {
        await fetchMatches(authProvider);
      } else {
        throw Exception('Erreur serveur : ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating score: $e');
      rethrow;
    }
  }

  Future<void> createMatch(AuthProvider authProvider, int pouleTeamId, String dateMatch, {
    String categorie = 'SENIOR',
    String lieu = '',
    String phase = 'Phase de Groupes',
  }) async {
    final token = authProvider.token;
    if (token == null) return;

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.post(
        Uri.parse('$apiUrl/matches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'poule_team_id': pouleTeamId,
          'date_match': dateMatch,
          'categorie': categorie,
          if (lieu.isNotEmpty) 'lieu': lieu,
          'phase': phase,
        }),
      );

      if (response.statusCode == 201) {
        await fetchMatches(authProvider);
      } else {
        throw Exception('Erreur serveur : ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating match: $e');
      rethrow;
    }
  }

  Future<void> updateMatchStatus(AuthProvider authProvider, int matchId, String statut) async {
    final token = authProvider.token;
    if (token == null) return;

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.put(
        Uri.parse('$apiUrl/matches/$matchId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'statut': statut}),
      );

      if (response.statusCode == 200) {
        await fetchMatches(authProvider);
      } else {
        debugPrint('Error updating status: ${response.statusCode} ${response.body}');
        throw Exception('Erreur serveur : ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating match status: $e');
      rethrow;
    }
  }

  Future<void> addMatchEvent(AuthProvider authProvider, int matchId, String type, {int? playerId, int? minute, String? description}) async {
    final token = authProvider.token;
    if (token == null) return;

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.post(
        Uri.parse('$apiUrl/matches/$matchId/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'type': type,
          'player_id': playerId,
          'minute': minute ?? 1,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        await fetchMatches(authProvider);
      } else {
        debugPrint('Error adding event: ${response.statusCode} ${response.body}');
        throw Exception('Erreur serveur : ${response.body}');
      }
    } catch (e) {
      debugPrint('Error adding match event: $e');
      rethrow;
    }
  }
}
