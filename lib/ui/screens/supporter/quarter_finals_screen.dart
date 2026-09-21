import 'package:flutter/material.dart';
import '../../../services/asc_service.dart';
import '../../widgets/team_logo.dart';
import 'simulator_screen.dart';

class QuarterFinalsScreen extends StatefulWidget {
  final String category;
  const QuarterFinalsScreen({super.key, this.category = 'SENIOR'});

  @override
  State<QuarterFinalsScreen> createState() => _QuarterFinalsScreenState();
}

class _QuarterFinalsScreenState extends State<QuarterFinalsScreen> {
  final AscService _ascService = AscService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _matchs = [];

  @override
  void initState() {
    super.initState();
    _fetchPredictions();
  }

  Future<void> _fetchPredictions() async {
    try {
      final res = await _ascService.getQuarterFinalsPrediction(widget.category);
      if (res['error'] != null) {
        setState(() {
          _error = res['error'];
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _matchs = res['matchs'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final teamA = match['team_a'];
    final teamB = match['team_b'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0A5C36),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text(
                  match['label'] ?? 'Quart de Finale',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Team A
                Expanded(
                  child: Column(
                    children: [
                      TeamLogo(
                        teamName: teamA['nom_equipe'],
                        logoUrl: teamA['logo'],
                        fallbackColor: const Color(0xFF0A5C36),
                        size: 50,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        teamA['nom_equipe'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match['team_a_qualification'],
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // VS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, fontSize: 16),
                  ),
                ),
                // Team B
                Expanded(
                  child: Column(
                    children: [
                      TeamLogo(
                        teamName: teamB['nom_equipe'],
                        logoUrl: teamB['logo'],
                        fallbackColor: const Color(0xFFC62828),
                        size: 50,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        teamB['nom_equipe'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match['team_b_qualification'],
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
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
        title: Text('Prédictions 1/4 Finale (${widget.category})', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A5C36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SimulatorScreen(category: widget.category)),
          );
        },
        backgroundColor: Colors.amber[700],
        icon: const Icon(Icons.videogame_asset, color: Colors.white),
        label: const Text('Simulateur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ce tableau est généré automatiquement selon le classement actuel. Il peut changer si d\'autres matchs sont joués.',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._matchs.map((m) => _buildMatchCard(m)),
                  ],
                ),
    );
  }
}
