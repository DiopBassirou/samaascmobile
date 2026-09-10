import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> with SingleTickerProviderStateMixin {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  List<dynamic> _pendingAscs = [];
  bool _isLoading = true;
  String? _processingCode; // ASC en cours de traitement

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fetchPendingAscs();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingAscs() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/superadmin/ascs/pending'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _pendingAscs = jsonDecode(response.body);
          _isLoading = false;
        });
        _animController.forward(from: 0);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processRequest(String codeUnique, bool isApprove) async {
    setState(() => _processingCode = codeUnique);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final endpoint = isApprove ? 'approve' : 'reject';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/superadmin/ascs/$codeUnique/$endpoint'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isApprove ? '✅ ASC validée avec succès !' : '❌ ASC rejetée'),
            backgroundColor: isApprove ? Colors.green.shade700 : Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ));
          _fetchPendingAscs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur lors du traitement'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur de connexion'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _processingCode = null);
    }
  }

  Future<void> _showConfirmDialog(String codeUnique, String nomAsc, bool isApprove) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isApprove ? Icons.check_circle : Icons.cancel, color: isApprove ? Colors.green : Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(isApprove ? 'Valider l\'ASC' : 'Rejeter l\'ASC', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isApprove
              ? 'Voulez-vous valider l\'ASC "$nomAsc" ? Elle sera visible par tous les supporters pour s\'inscrire.'
              : 'Voulez-vous rejeter la demande de "$nomAsc" ? Cette action est définitive.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green.shade700 : Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _processRequest(codeUnique, isApprove);
            },
            child: Text(isApprove ? 'Oui, Valider' : 'Oui, Rejeter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          // App Bar personnalisée
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF0A1929),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A1929), Color(0xFF0A5C36)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.admin_panel_settings, color: Colors.greenAccent, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Super Admin', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                Text('Sama ASC Platform', style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _fetchPendingAscs,
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                              tooltip: 'Rafraîchir',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  _buildStatCard('🔔', '${_pendingAscs.length}', 'En attente', const Color(0xFFFF6B35)),
                  _buildStatDivider(),
                  _buildStatCard('🏆', '--', 'Validées', const Color(0xFF0A5C36)),
                  _buildStatDivider(),
                  _buildStatCard('👥', '--', 'Utilisateurs', const Color(0xFF1565C0)),
                ],
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 20,
                    decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Demandes en attente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A1929))),
                ],
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36))),
            )
          else if (_pendingAscs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF0A5C36)),
                    ),
                    const SizedBox(height: 20),
                    const Text('Tout est à jour !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A1929))),
                    const SizedBox(height: 8),
                    Text('Aucune demande en attente de validation.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5C36),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _fetchPendingAscs,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Rafraîchir'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asc = _pendingAscs[index];
                    final isProcessing = _processingCode == asc['code_unique'];
                    return _buildAscCard(asc, isProcessing);
                  },
                  childCount: _pendingAscs.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAscCard(Map<String, dynamic> asc, bool isProcessing) {
    final president = asc['president'];
    final nomComplet = president != null
        ? '${president['prenom'] ?? ''} ${president['nom'] ?? ''}'.trim()
        : 'Non renseigné';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // En-tête de la carte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1929), Color(0xFF0D2B45)],
                begin: Alignment.topLeft,
                end: Alignment.topRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Badge ASC
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('🏆', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asc['nom'] ?? 'N/A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 4),
                          Text('${asc['zone'] ?? ''} • ${asc['ville'] ?? ''}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge "EN ATTENTE"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.5)),
                  ),
                  child: const Text('⏳ En attente', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Infos de la carte
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.person_outline, 'Président', nomComplet),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.phone_outlined, 'Téléphone', president?['telephone'] ?? 'Non renseigné'),
                if (asc['code_unique'] != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.key_outlined, 'Code ASC', asc['code_unique']),
                ],
                if (asc['recepisse_path'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.description_outlined, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text('Récépissé soumis', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
                        Spacer(),
                        Icon(Icons.chevron_right, color: Colors.blue, size: 18),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Boutons d'action
                if (isProcessing)
                  const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: CircularProgressIndicator(color: Color(0xFF0A5C36)),
                  ))
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rejeter', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _showConfirmDialog(asc['code_unique'], asc['nom'], false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A5C36),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 3,
                            shadowColor: const Color(0xFF0A5C36).withValues(alpha: 0.3),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Valider l\'ASC', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _showConfirmDialog(asc['code_unique'], asc['nom'], true),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text('$label : ', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0A1929)))),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 50, color: Colors.grey[200]);
  }
}
