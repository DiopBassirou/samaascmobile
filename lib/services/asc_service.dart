import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/api_routes.dart';

class AscService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// URL de base sans /api (pour accéder aux fichiers storage)
  String getBaseUrlWithoutApi() => _baseUrl.replaceAll('/api', '');

  /// Charge la liste de toutes les ASC validées (sans token - route publique)
  Future<List<Map<String, dynamic>>> getValidatedAscs() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/ascs'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
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
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
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
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Erreur lors de la création de l\'ASC');
    }
  }

  Future<Map<String, dynamic>> createAsc(String nom, String ville, String zone, XFile? recepisse) async {
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
      final bytes = await recepisse.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'recepisse', 
        bytes,
        filename: recepisse.name,
      ));
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
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
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
      return jsonDecode(utf8.decode(response.bodyBytes));
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
      return jsonDecode(utf8.decode(response.bodyBytes))['settings'];
    } else {
      throw Exception('Erreur de mise à jour des paramètres');
    }
  }

  Future<String?> uploadLogo(XFile logoFile) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/settings/logo'));
    
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    final bytes = await logoFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'logo', 
      bytes,
      filename: logoFile.name,
    ));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseData)['logo_url'];
    } else {
      throw Exception('Erreur upload logo : $responseData');
    }
  }

  /// Créer un match en tant que Super Admin
  /// Si score_a et score_b sont fournis, le match est créé directement comme TERMINE
  Future<Map<String, dynamic>> createSuperAdminMatch({
    required int pouleTeamAId,
    required int pouleTeamBId,
    required String dateMatch,
    required String categorie,
    String? lieu,
    String? phase,
    int? scoreA,
    int? scoreB,
  }) async {
    final token = await _getToken();
    final body = <String, dynamic>{
      'poule_team_a_id': pouleTeamAId,
      'poule_team_b_id': pouleTeamBId,
      'date_match': dateMatch,
      'categorie': categorie,
      'lieu': lieu,
      'phase': phase ?? 'Phase de Groupes',
    };
    if (scoreA != null && scoreB != null) {
      body['score_a'] = scoreA;
      body['score_b'] = scoreB;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/superadmin/matches'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['message'] ?? 'Erreur lors de la création du match');
    }
  }

  /// Modifier le score d'un match existant (Super Admin)
  Future<Map<String, dynamic>> updateSuperAdminMatchScore(int matchId, int scoreAsc, int scoreAdv, {String statut = 'TERMINE'}) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/superadmin/matches/$matchId/score'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'score_asc': scoreAsc,
        'score_adv': scoreAdv,
        'statut': statut,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['message'] ?? 'Erreur mise à jour du score');
    }
  }

  /// Upload le logo d'une ASC spécifique (Super Admin)
  Future<String?> uploadAscLogo(String codeUnique, XFile logoFile) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/superadmin/ascs/$codeUnique/logo'));

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    final bytes = await logoFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'logo', 
      bytes,
      filename: logoFile.name,
    ));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseData)['logo_url'];
    } else {
      throw Exception('Erreur upload logo : $responseData');
    }
  }

  /// Ajoute un joueur à une ASC spécifique (Super Admin)
  Future<Map<String, dynamic>> addSuperAdminPlayer(String codeUnique, String nom, String poste) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/superadmin/ascs/$codeUnique/players'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nom': nom,
        'poste': poste,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['message'] ?? 'Erreur lors de l\'ajout du joueur');
    }
  }

  /// Supprime un match (Super Admin)
  Future<void> deleteSuperAdminMatch(int matchId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/superadmin/matches/$matchId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['message'] ?? 'Erreur lors de la suppression');
    }
  }

  /// Met à jour un match (Super Admin)
  Future<Map<String, dynamic>> updateSuperAdminMatch(int matchId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/superadmin/matches/$matchId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['message'] ?? 'Erreur lors de la mise à jour');
    }
  }

  /// Récupère tous les matchs pour le Super Admin
  Future<List<Map<String, dynamic>>> getSuperAdminMatches() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/superadmin/matches'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Erreur de chargement des matchs');
    }
  }
}
