import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_provider.dart';

class ClassementProvider with ChangeNotifier {
  List<dynamic> _teams = [];
  bool _isLoading = false;

  List<dynamic> get teams => _teams;
  bool get isLoading => _isLoading;

  Future<void> fetchClassement(AuthProvider authProvider) async {
    final token = authProvider.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/classement'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _teams = json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching classement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
