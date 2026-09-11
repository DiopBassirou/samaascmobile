import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../providers/auth_provider.dart';
import 'dart:ui' as ui;

class SuperAdminStatsTab extends StatefulWidget {
  const SuperAdminStatsTab({super.key});

  @override
  State<SuperAdminStatsTab> createState() => _SuperAdminStatsTabState();
}

class _SuperAdminStatsTabState extends State<SuperAdminStatsTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api';

      final response = await http.get(
        Uri.parse('$apiUrl/superadmin/devices/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            // Utiliser utf8.decode pour bien gérer les accents comme pour le reste
            _stats = json.decode(utf8.decode(response.bodyBytes));
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: TextStyle(color: Colors.grey[700])),
            Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStats,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final int total = _stats?['total_installations'] ?? 0;
    final int activeToday = _stats?['active_today'] ?? 0;
    final int activeWeek = _stats?['active_this_week'] ?? 0;
    final List<dynamic> breakdown = _stats?['asc_breakdown'] ?? [];

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aperçu de l\'utilisation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)),
            ),
            const SizedBox(height: 16),
            
            // Cartes de statistiques globales
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Installations',
                    value: total.toString(),
                    icon: Icons.download,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Actifs Aujourd\'hui',
                    value: activeToday.toString(),
                    icon: Icons.touch_app,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Actifs cette semaine',
                    value: activeWeek.toString(),
                    icon: Icons.date_range,
                    color: Colors.orange,
                  ),
                ),
                Expanded(child: Container()), // Espace vide
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Répartition par ASC',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)),
            ),
            const SizedBox(height: 12),

            if (breakdown.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: const Center(child: Text("Aucune donnée d'équipe disponible")),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: breakdown.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = breakdown[index];
                    final ascName = item['asc']?['nom'] ?? item['asc_code'] ?? 'Inconnu';
                    final ascTotal = item['total'] ?? 0;
                    // Calculer le pourcentage par rapport au total (ou au total des inscrits)
                    double percentage = total > 0 ? (ascTotal / total) : 0;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0A5C36).withValues(alpha: 0.1),
                        child: const Icon(Icons.shield, color: Color(0xFF0A5C36), size: 20),
                      ),
                      title: Text(ascName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A5C36)),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 6,
                          ),
                        ],
                      ),
                      trailing: Text(
                        '$ascTotal',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0A5C36)),
                      ),
                    );
                  },
                ),
              ),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
