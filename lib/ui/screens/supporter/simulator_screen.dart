import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/asc_service.dart';
import '../../../providers/match_provider.dart';
import '../../widgets/team_logo.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final AscService _ascService = AscService();
  bool _isLoading = false;
  
  List<dynamic> _predictedMatchs = [];
  List<dynamic> _simulatedPoules = [];
  
  final Map<int, TextEditingController> _scoreAControllers = {};
  final Map<int, TextEditingController> _scoreBControllers = {};

  List<dynamic> _remainingMatches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRemainingMatches();
    });
  }

  Future<void> _fetchRemainingMatches() async {
    setState(() => _isLoading = true);
    try {
      final apiUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000/api');
      final response = await http.get(Uri.parse('$apiUrl/all-matches'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final dates = data['dates'] ?? [];
        List<dynamic> allMatches = [];
        for (var d in dates) {
          allMatches.addAll(d['matches'] ?? []);
        }

        final remainingMatches = allMatches.where((m) => 
          m['categorie'] == 'SENIOR' && 
          ['A_VENIR', 'EN_COURS', 'MI_TEMPS', 'DEUXIEME_MI_TEMPS'].contains(m['statut'])
        ).toList();

        for (var m in remainingMatches) {
          _scoreAControllers[m['id']] = TextEditingController(text: (m['score_home'] ?? 0).toString());
          _scoreBControllers[m['id']] = TextEditingController(text: (m['score_away'] ?? 0).toString());
        }

        setState(() {
          _remainingMatches = remainingMatches;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var c in _scoreAControllers.values) { c.dispose(); }
    for (var c in _scoreBControllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _runSimulation() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> simulatedMatches = [];
      for (var id in _scoreAControllers.keys) {
        simulatedMatches.add({
          'id': id,
          'score_asc': int.tryParse(_scoreAControllers[id]?.text ?? '0') ?? 0,
          'score_adv': int.tryParse(_scoreBControllers[id]?.text ?? '0') ?? 0,
        });
      }

      final res = await _ascService.simulatePredictions(simulatedMatches);
      if (res['predictions']?['error'] != null) {
        throw Exception(res['predictions']['error']);
      }

      setState(() {
        _predictedMatchs = res['predictions']['matchs'] ?? [];
        _simulatedPoules = res['poules'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildSimulationForm() {
    if (_remainingMatches.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Tous les matchs de poules sont terminés !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Matchs restants (entrez des scores imaginaires)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A5C36))),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _remainingMatches.length,
          itemBuilder: (ctx, i) {
            final m = _remainingMatches[i];
            if(!_scoreAControllers.containsKey(m['id'])) return const SizedBox();
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(child: Text(m['home'] ?? 'Equipe A', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: TextField(
                        controller: _scoreAControllers[m['id']],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('-', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      width: 40,
                      child: TextField(
                        controller: _scoreBControllers[m['id']],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m['away'] ?? 'Equipe B', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            );
          },
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _runSimulation,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Simuler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulatedResults() {
    if (_predictedMatchs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 2),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Prédictions 1/4 (Simulées)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
        ),
        ..._predictedMatchs.map((match) => _buildMatchCard(match)),
        const Divider(thickness: 2),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Classement des Poules (Simulé)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0A5C36))),
        ),
        ..._simulatedPoules.map((poule) => _buildPouleTable(poule)),
        const SizedBox(height: 32),
      ],
    );
  }
  
  Widget _buildPouleTable(Map<String, dynamic> pouleData) {
    final teams = pouleData['teams'] as List<dynamic>? ?? [];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0A5C36),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Text(pouleData['nom'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 50,
              columns: const [
                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text('Équipe', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('J', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Diff', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)))),
              ],
              rows: List<DataRow>.generate(teams.length, (index) {
                final t = teams[index];
                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Row(
                      children: [
                        if (t['logo'] != null) TeamLogo(teamName: t['nom_equipe'], logoUrl: t['logo'], fallbackColor: Colors.grey, size: 20) else const Icon(Icons.shield, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(t['nom_equipe'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    )),
                    DataCell(Text('${t['joues'] ?? 0}')),
                    DataCell(Text('${(t['buts_pour'] ?? 0) - (t['buts_contre'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${t['points'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)))),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final teamA = match['team_a'];
    final teamB = match['team_b'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.science, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(match['label'] ?? 'Quart de Finale', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TeamLogo(teamName: teamA['nom_equipe'], logoUrl: teamA['logo'], fallbackColor: const Color(0xFF0A5C36), size: 50),
                      const SizedBox(height: 8),
                      Text(teamA['nom_equipe'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(match['team_a_qualification'], textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, fontSize: 16)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      TeamLogo(teamName: teamB['nom_equipe'], logoUrl: teamB['logo'], fallbackColor: const Color(0xFFC62828), size: 50),
                      const SizedBox(height: 8),
                      Text(teamB['nom_equipe'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(match['team_b_qualification'], textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Simulateur 1/4 Finale', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: Colors.amber[700]))
        : SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.amber.withValues(alpha: 0.1),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Ceci est une simulation virtuelle. Les scores que vous entrez ici ne modifient pas la vraie base de données.",
                          style: TextStyle(color: Colors.brown, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSimulationForm(),
                _buildSimulatedResults(),
              ],
            ),
          ),
    );
  }
}
