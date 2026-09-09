import 'package:flutter/material.dart';
import 'package:sama_asc_mobile/services/bureau_service.dart';
import 'package:sama_asc_mobile/providers/auth_provider.dart';

class BureauProvider with ChangeNotifier {
  final BureauService _bureauService = BureauService();
  
  List<dynamic> _members = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBureau(AuthProvider authProvider) async {
    if (authProvider.token == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _members = await _bureauService.fetchBureau(authProvider.token!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> assignRole(AuthProvider authProvider, String search, int roleId) async {
    if (authProvider.token == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      await _bureauService.assignRole(authProvider.token!, search, roleId);
      // Recharger le bureau
      await fetchBureau(authProvider);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
