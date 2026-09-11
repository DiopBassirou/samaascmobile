import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_provider.dart';

class ClassementProvider with ChangeNotifier {
  Map<String, dynamic> _zonesData = {};
  bool _isLoading = false;

  // All matches data (BeSoccer style)
  List<dynamic> _allMatchDates = [];
  List<String> _availableZones = [];
  List<String> _availableCategories = ['SENIOR', 'CADET'];
  bool _isLoadingMatches = false;

  Map<String, dynamic> get zonesData => _zonesData;
  bool get isLoading => _isLoading;

  List<dynamic> get allMatchDates => _allMatchDates;
  List<String> get availableZones => _availableZones;
  List<String> get availableCategories => _availableCategories;
  bool get isLoadingMatches => _isLoadingMatches;

  Future<void> fetchClassement([AuthProvider? authProvider]) async {
    final token = authProvider?.token;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/classement'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _zonesData = json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint('Error fetching classement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllMatches({AuthProvider? authProvider, String? zone, String? categorie}) async {
    final token = authProvider?.token;

    _isLoadingMatches = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';
      final params = <String, String>{};
      if (zone != null && zone.isNotEmpty) params['zone'] = zone;
      if (categorie != null && categorie.isNotEmpty) params['categorie'] = categorie;

      final uri = Uri.parse('$apiUrl/all-matches').replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _allMatchDates = data['dates'] ?? [];
        _availableZones = List<String>.from(data['zones'] ?? []);
        _availableCategories = List<String>.from(data['categories'] ?? ['SENIOR', 'CADET']);
      }
    } catch (e) {
      debugPrint('Error fetching all matches: $e');
    } finally {
      _isLoadingMatches = false;
      notifyListeners();
    }
  }
}
