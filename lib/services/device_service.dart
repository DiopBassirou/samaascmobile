import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  static const String _keyDeviceUuid = 'app_device_uuid';
  static const String _keyFavAscCode = 'favorite_asc_code';
  static const String _keyFavAscNom = 'favorite_asc_nom';
  static const String _keyFavAscLogo = 'favorite_asc_logo';

  /// Récupère ou génère un UUID unique d'appareil
  Future<String> getOrCreateDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_keyDeviceUuid);
    if (uuid == null || uuid.isEmpty) {
      final rand = Random().nextInt(999999);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      uuid = 'dev_${timestamp}_$rand';
      await prefs.setString(_keyDeviceUuid, uuid);
    }
    return uuid;
  }

  /// Sauvegarde l'ASC favorite
  Future<void> saveFavoriteAsc(Map<String, dynamic> asc) async {
    final prefs = await SharedPreferences.getInstance();
    final ascCode = asc['code_unique']?.toString() ?? '';
    final ascNom = asc['nom']?.toString() ?? '';
    final ascLogo = asc['logo_url']?.toString() ?? '';

    await prefs.setString(_keyFavAscCode, ascCode);
    await prefs.setString(_keyFavAscNom, ascNom);
    await prefs.setString(_keyFavAscLogo, ascLogo);

    // Envoi du ping au backend
    await ping(ascCode: ascCode);
  }

  /// Récupère l'ASC favorite stockée
  Future<Map<String, String>?> getFavoriteAsc() async {
    final prefs = await SharedPreferences.getInstance();
    final ascCode = prefs.getString(_keyFavAscCode);
    final ascNom = prefs.getString(_keyFavAscNom);
    final ascLogo = prefs.getString(_keyFavAscLogo);

    if (ascCode == null || ascCode.isEmpty) {
      return null;
    }

    return {
      'code_unique': ascCode,
      'nom': ascNom ?? '',
      'logo_url': ascLogo ?? '',
    };
  }

  /// Envoie un heartbeat/ping à l'API
  Future<void> ping({String? ascCode, String? fcmToken}) async {
    try {
      final uuid = await getOrCreateDeviceUuid();
      
      String platform = 'Web';
      if (!kIsWeb) {
        if (Platform.isAndroid) platform = 'Android';
        if (Platform.isIOS) platform = 'iOS';
      }

      final prefs = await SharedPreferences.getInstance();
      final currentAsc = ascCode ?? prefs.getString(_keyFavAscCode);

      final response = await http.post(
        Uri.parse('$_baseUrl/device/ping'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'device_uuid': uuid,
          'fcm_token': fcmToken,
          'asc_code': currentAsc,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Device ping OK');
      }
    } catch (e) {
      debugPrint('Device ping error: $e');
    }
  }
}
