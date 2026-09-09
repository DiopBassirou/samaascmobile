import 'dart:io';
import 'package:flutter/material.dart';
import '../services/asc_service.dart';

class AscProvider with ChangeNotifier {
  final AscService _ascService = AscService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> createAsc(String nom, String ville, String zone, File? recepisse) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _ascService.createAsc(nom, ville, zone, recepisse);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinAsc(String codeUnique) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _ascService.joinAsc(codeUnique);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Map<String, dynamic>? _settings;
  Map<String, dynamic>? get settings => _settings;

  Future<void> fetchSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _ascService.fetchSettings();
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(String nom, String ville, String zone, int cotisationObjectif) async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _ascService.updateSettings(nom, ville, zone, cotisationObjectif);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadLogo(File logoFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newUrl = await _ascService.uploadLogo(logoFile);
      if (_settings != null && newUrl != null) {
        _settings!['logo_url'] = newUrl;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
