import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../services/finance_service.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceService _service = FinanceService();
  
  bool _isLoading = false;
  List<dynamic> _transactions = [];
  double _targetCotisation = 250000;
  double _solde = 0.0;

  bool get isLoading => _isLoading;
  List<dynamic> get transactions => _transactions;
  double get targetCotisation => _targetCotisation;
  double get solde => _solde;

  Future<void> fetchFinances(dynamic authProvider) async {
    final token = authProvider.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      
      // Fetch target cotisation
      final settingsRes = await http.get(
        Uri.parse('$apiUrl/settings'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (settingsRes.statusCode == 200) {
        final settingsData = json.decode(settingsRes.body);
        _targetCotisation = double.tryParse(settingsData['cotisation_objectif'].toString()) ?? 250000;
      }

      final response = await http.get(
        Uri.parse('$apiUrl/finances'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _transactions = json.decode(response.body);
        _solde = 0;
        for (var t in _transactions) {
          if (t['type'] == 'ENTREE') _solde += double.tryParse(t['montant'].toString()) ?? 0;
          else if (t['type'] == 'SORTIE') _solde -= double.tryParse(t['montant'].toString()) ?? 0;
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFinance(String type, String categorie, double montant) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addFinance(type, categorie, montant);
      // Removed implicit call to fetchFinances() as it now requires authProvider
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String getExportUrl(String token) {
    return _service.getExportUrl(token);
  }
}
