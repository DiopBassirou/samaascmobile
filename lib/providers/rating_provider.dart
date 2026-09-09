import 'package:flutter/material.dart';
import '../services/rating_service.dart';

class RatingProvider with ChangeNotifier {
  final RatingService _service = RatingService();
  
  bool _isLoading = false;
  List<dynamic> _matches = [];
  List<dynamic> _players = [];
  final Map<int, double> _ratings = {}; // playerId -> note (1-10)

  bool get isLoading => _isLoading;
  List<dynamic> get matches => _matches;
  List<dynamic> get players => _players;
  Map<int, double> get ratings => _ratings;

  Future<void> fetchMatches() async {
    _isLoading = true;
    notifyListeners();
    try {
      _matches = await _service.getMatches();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPlayersForMatch(int matchId) async {
    _isLoading = true;
    _players = [];
    _ratings.clear();
    notifyListeners();
    try {
      _players = await _service.getPlayersForMatch(matchId);
      for (var player in _players) {
        _ratings[player['id']] = 5.0; // Note moyenne par défaut
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateRating(int playerId, double rating) {
    _ratings[playerId] = rating;
    notifyListeners();
  }

  Future<void> submitAllRatings(int matchId) async {
    _isLoading = true;
    notifyListeners();
    try {
      for (var playerId in _ratings.keys) {
        await _service.submitRating(matchId, playerId, _ratings[playerId]!.toInt());
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
