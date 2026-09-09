import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    // En mode Offline-First, on chargerait aussi l'utilisateur en local ici
    notifyListeners();
  }

  Future<void> register(String nom, String prenom, String telephone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _authService.register(nom, prenom, telephone, password);
      
      // Auto-login after registration if the API returns a token directly
      if (data.containsKey('token')) {
        _token = data['token'];
        _user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
      } else {
        // If not, we just login manually
        await login(telephone, password);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login(String telephone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _authService.login(telephone, password);
      _token = data['token'];
      _user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}

