import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> getFinances() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/finances'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erreur de chargement des finances');
    }
  }

  Future<Map<String, dynamic>> addFinance(String type, String motif, double montant) async {
    final token = await _getToken();
    
    // Si c'est une DEPENSE, le backend attend SORTIE
    String backendType = type == 'DEPENSE' ? 'SORTIE' : type;
    
    final response = await http.post(
      Uri.parse('$_baseUrl/finances'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'type': backendType,
        'motif': motif,
        'montant': montant,
        'date_transaction': DateTime.now().toIso8601String().split('T')[0],
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erreur lors de la sauvegarde: ${response.body}');
    }
  }

  String getExportUrl(String token) {
    return '$_baseUrl/finances/export?token=$token'; 
  }
}
