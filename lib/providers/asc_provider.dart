import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/asc_service.dart';

class AscProvider with ChangeNotifier {
  final AscService _ascService = AscService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _ascs = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get ascs => _ascs;

  Future<void> fetchSuperAdminAscs() async {
    _isLoading = true;
    notifyListeners();
    try {
      _ascs = await _ascService.getSuperAdminAscs();
    } catch (e) {
      debugPrint('Error fetching superadmin ascs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createSuperAdminAsc(String nom, String zone, {String ville = 'Dakar'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _ascService.createSuperAdminAsc(nom, zone, ville: ville);
      // Recharger immédiatement la liste partagée de toutes les ASCs
      await fetchSuperAdminAscs();
      return res;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createAsc(String nom, String ville, String zone, XFile? recepisse) async {
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

  Future<void> uploadLogo(XFile logoFile) async {
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
