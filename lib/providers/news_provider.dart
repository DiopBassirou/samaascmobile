import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/news_model.dart';
import 'auth_provider.dart';

class NewsProvider with ChangeNotifier {
  List<Announcement> _news = [];
  bool _isLoading = false;

  List<Announcement> get news => _news;
  bool get isLoading => _isLoading;

  Future<void> fetchNews(AuthProvider authProvider) async {
    final token = authProvider.token;
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/news'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _news = data.map((json) => Announcement.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des annonces: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNews(AuthProvider authProvider, String title, String message, String type) async {
    final token = authProvider.token;
    if (token == null) return;

    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';
      final response = await http.post(
        Uri.parse('$apiUrl/news'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: json.encode({'title': title, 'message': message, 'type': type}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        _news.insert(0, Announcement.fromJson(data));
        notifyListeners();
      } else {
        throw Exception('Échec de la création de l\'annonce');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'annonce: $e');
      rethrow;
    }
  }
}
