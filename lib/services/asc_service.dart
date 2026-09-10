import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_routes.dart';

class AscService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Charge la liste de toutes les ASC validées (sans token - route publique)
  Future<List<Map<String, dynamic>>> getValidatedAscs() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ascs'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Impossible de charger les équipes');
    }
  }

  Future<List<Map<String, dynamic>>> getSuperAdminAscs() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/superadmin/ascs'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Impossible de charger les équipes super admin');
    }
  }

  Future<Map<String, dynamic>> createSuperAdminAsc(String nom, String zone) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/superadmin/ascs'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nom': nom,
        'zone': zone,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la création de l\'ASC');
    }
  }

  Future<Map<String, dynamic>> createAsc(String nom, String ville, String zone, File? recepisse) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl${ApiRoutes.ascCreate}'));
    
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['nom'] = nom;
    request.fields['ville'] = ville;
    request.fields['zone'] = zone;

    if (recepisse != null) {
      request.files.add(await http.MultipartFile.fromPath('recepisse', recepisse.path));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return jsonDecode(responseData);
    } else {
      throw Exception('Erreur : $responseData');
    }
  }

  Future<Map<String, dynamic>> joinAsc(String codeUnique) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl${ApiRoutes.ascJoin}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code_unique': codeUnique}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur inconnue');
    }
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/settings'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Impossible de charger les paramètres');
    }
  }

  Future<Map<String, dynamic>> updateSettings(String nom, String ville, String zone, int cotisationObjectif) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nom_asc': nom,
        'ville': ville,
        'zone': zone,
        'cotisation_objectif': cotisationObjectif,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['settings'];
    } else {
      throw Exception('Erreur de mise à jour des paramètres');
    }
  }

  Future<String?> uploadLogo(File logoFile) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/settings/logo'));
    
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.files.add(await http.MultipartFile.fromPath('logo', logoFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseData)['logo_url'];
    } else {
      throw Exception('Erreur upload logo : $responseData');
    }
  }
}

