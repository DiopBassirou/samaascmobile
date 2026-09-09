import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/convocation_service.dart';

class ConvocationProvider with ChangeNotifier {
  final ConvocationService _service = ConvocationService();
  
  bool _isLoading = false;
  List<dynamic> _players = [];
  final Map<int, String> _selections = {};

  bool get isLoading => _isLoading;
  List<dynamic> get players => _players;
  Map<int, String> get selections => _selections;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchPlayers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token != null) {
        _players = await _service.getPlayers(token);
        for (var player in _players) {
          _selections[player['id']] = 'REPOS';
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSelection(int playerId, String status) {
    _selections[playerId] = status;
    notifyListeners();
  }

  Future<void> submit(int matchId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token != null) {
        List<Map<String, dynamic>> payload = [];
        _selections.forEach((playerId, status) {
          payload.add({'player_id': playerId, 'statut': status});
        });
        await _service.submitConvocations(token, matchId, payload);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
