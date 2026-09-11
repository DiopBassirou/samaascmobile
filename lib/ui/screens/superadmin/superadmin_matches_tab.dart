import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/poule_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/asc_service.dart';

class SuperAdminMatchesTab extends StatefulWidget {
  const SuperAdminMatchesTab({super.key});

  @override
  State<SuperAdminMatchesTab> createState() => _SuperAdminMatchesTabState();
}

class _SuperAdminMatchesTabState extends State<SuperAdminMatchesTab> {
  final AscService _ascService = AscService();

  String _categorie = 'SENIOR';
  int? _selectedPouleIndex;
  int? _teamAId;
  int? _teamBId;

  DateTime _matchDate = DateTime.now();
  TimeOfDay _matchTime = const TimeOfDay(hour: 16, minute: 0);
  final _lieuController = TextEditingController();
  String _matchPhase = 'Phase de Groupes';
  static const _phases = ['Phase de Groupes', '1/4 Finale', '1/2 Finale', 'Finale', 'Match Amical'];

  // Score direct (optionnel)
  bool _hasScore = false;
  final _scoreAController = TextEditingController(text: '0');
  final _scoreBController = TextEditingController(text: '0');

  bool _isSubmitting = false;
  bool _isLoadingMatches = false;
  List<Map<String, dynamic>> _allMatches = [];
  String _matchStatusFilter = 'A_VENIR'; // 'A_VENIR' ou 'TERMINE'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final pouleProv = Provider.of<PouleProvider>(context, listen: false);
      pouleProv.fetchPoules(auth);
    });
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoadingMatches = true);
    try {
      final matches = await _ascService.getSuperAdminMatches();
      if (mounted) setState(() => _allMatches = matches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoadingMatches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PouleProvider>(
      builder: (context, pouleProv, _) {
        final filteredPoules = pouleProv.poules.where((p) => p['categorie'] == _categorie).toList();
        
        final displayedMatches = _allMatches.where((m) {
          final isSameCategory = m['categorie'] == _categorie;
          final isSameStatus = _matchStatusFilter == 'TERMINE' ? m['statut'] == 'TERMINE' : m['statut'] != 'TERMINE';
          return isSameCategory && isSameStatus;
        }).toList();

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0A5C36), Color(0xFF0F8A4B)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.sports_soccer, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Création Rapide de Matchs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Programmez ou enregistrez les résultats', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── CATÉGORIE ───
                _sectionTitle('Catégorie'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCatBtn('SENIOR', '🧑 Seniors', const Color(0xFF0A5C36)),
                    const SizedBox(width: 10),
                    _buildCatBtn('CADET', '🏃 Cadets', const Color(0xFF0F8A4B)),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── POULE ───
                if (filteredPoules.isEmpty)
                  _emptyBox('Aucune poule $_categorie disponible')
                else ...[
                  _sectionTitle('Poule'),
                  const SizedBox(height: 8),
                  _buildDropdown<int>(
                    value: _selectedPouleIndex != null && _selectedPouleIndex! < filteredPoules.length ? _selectedPouleIndex : null,
                    hint: 'Sélectionner une poule',
                    icon: Icons.emoji_events_outlined,
                    items: List.generate(filteredPoules.length, (i) {
                      return DropdownMenuItem(value: i, child: Text(filteredPoules[i]['nom'] ?? 'Poule ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)));
                    }),
                    onChanged: (val) => setState(() { _selectedPouleIndex = val; _teamAId = null; _teamBId = null; }),
                  ),

                  if (_selectedPouleIndex != null && _selectedPouleIndex! < filteredPoules.length) ..._buildTeamSelectors(filteredPoules.cast<Map<String, dynamic>>()),

                  // ─── DATE & HEURE ───
                  _sectionTitle('Date & Heure'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final dt = await showDatePicker(
                              context: context,
                              initialDate: _matchDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (dt != null) setState(() => _matchDate = dt);
                          },
                          child: _infoBox(Icons.calendar_today, '${_matchDate.day}/${_matchDate.month}/${_matchDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: _matchTime);
                            if (t != null) setState(() => _matchTime = t);
                          },
                          child: _infoBox(Icons.access_time, '${_matchTime.hour.toString().padLeft(2, '0')}:${_matchTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── LIEU ───
                  _sectionTitle('Lieu'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lieuController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Terrain HLM Grand Yoff...',
                      prefixIcon: const Icon(Icons.location_on, color: Color(0xFF0A5C36)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── PHASE ───
                  _sectionTitle('Phase'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _matchPhase,
                    hint: 'Phase',
                    icon: Icons.workspaces_outline,
                    items: _phases.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _matchPhase = val ?? 'Phase de Groupes'),
                  ),
                  const SizedBox(height: 16),

                  // ─── SCORE DIRECT ───
                  SwitchListTile(
                    title: const Text('Match déjà joué ? (Score direct)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Activez pour saisir le score final maintenant'),
                    value: _hasScore,
                    activeColor: const Color(0xFF0A5C36),
                    onChanged: (val) => setState(() => _hasScore = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_hasScore) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _scoreAController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Éq. A',
                              filled: true,
                              fillColor: Colors.green.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('-', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _scoreBController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Éq. B',
                              filled: true,
                              fillColor: Colors.red.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ─── BOUTON CRÉER ───
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5C36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.add_circle),
                      label: Text(_isSubmitting ? 'Enregistrement...' : 'Créer le Match', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: _isSubmitting ? null : _submitMatch,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ─── MATCHS CRÉÉS / FILTRÉS ───
                const Divider(height: 40, thickness: 1.5),
                _sectionTitle('Matchs $_categorie'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _matchStatusFilter = 'A_VENIR'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _matchStatusFilter == 'A_VENIR' ? Colors.orange : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text('Programmés', style: TextStyle(color: _matchStatusFilter == 'A_VENIR' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _matchStatusFilter = 'TERMINE'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _matchStatusFilter == 'TERMINE' ? Colors.green : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text('Terminés', style: TextStyle(color: _matchStatusFilter == 'TERMINE' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (_isLoadingMatches)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)))
                else if (displayedMatches.isEmpty)
                  _emptyBox('Aucun match $_matchStatusFilter pour les $_categorie')
                else
                  ...displayedMatches.map((m) {
                    final match = m['match'] ?? m;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF0A5C36), child: Icon(Icons.sports_soccer, color: Colors.white, size: 20)),
                        title: Text('${match['asc_code'] ?? '?'} vs ${match['opponent']?['nom_equipe'] ?? '?'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${match['statut'] ?? ''} — ${match['score_asc'] ?? 0} : ${match['score_adv'] ?? 0}'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) async {
                            if (val == 'edit') {
                              _showEditMatchDialog(match);
                            } else if (val == 'delete') {
                              try {
                                await _ascService.deleteSuperAdminMatch(match['id']);
                                setState(() {
                                  _allMatches.removeWhere((element) => element['id'] == match['id']);
                                });
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match supprimé avec succès'), backgroundColor: Colors.green));
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Modifier', style: TextStyle(color: Colors.blue))]),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitMatch() async {
    if (_teamAId == null || _teamBId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les 2 équipes'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dateTime = DateTime(
      _matchDate.year, _matchDate.month, _matchDate.day,
      _matchTime.hour, _matchTime.minute,
    );

    try {
      final result = await _ascService.createSuperAdminMatch(
        pouleTeamAId: _teamAId!,
        pouleTeamBId: _teamBId!,
        dateMatch: dateTime.toIso8601String(),
        categorie: _categorie,
        lieu: _lieuController.text.trim().isEmpty ? null : _lieuController.text.trim(),
        phase: _matchPhase,
        scoreA: _hasScore ? int.tryParse(_scoreAController.text) : null,
        scoreB: _hasScore ? int.tryParse(_scoreBController.text) : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Match créé !'),
          backgroundColor: Colors.green,
        ),
      );
      
      _fetchMatches(); // Rafraîchir la liste après création

      setState(() {
        _teamAId = null;
        _teamBId = null;
        _scoreAController.text = '0';
        _scoreBController.text = '0';
        _hasScore = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showEditMatchDialog(Map<String, dynamic> match) {
    DateTime matchDate = match['date_match'] != null ? DateTime.tryParse(match['date_match']) ?? DateTime.now() : DateTime.now();
    TimeOfDay matchTime = TimeOfDay(hour: matchDate.hour, minute: matchDate.minute);
    
    final lieuController = TextEditingController(text: match['lieu'] ?? '');
    String matchPhase = match['phase'] ?? 'Phase de Groupes';
    
    final scoreAController = TextEditingController(text: (match['score_asc'] ?? 0).toString());
    final scoreBController = TextEditingController(text: (match['score_adv'] ?? 0).toString());
    
    // Statut modifiable
    const statuts = ['A_VENIR', 'EN_COURS', 'MI_TEMPS', 'TERMINE'];
    String matchStatut = statuts.contains(match['statut']) ? match['statut'] : 'A_VENIR';
    
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Modifier Match', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date & Heure
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final dt = await showDatePicker(context: context, initialDate: matchDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (dt != null) setStateDialog(() => matchDate = DateTime(dt.year, dt.month, dt.day, matchTime.hour, matchTime.minute));
                        },
                        child: _infoBox(Icons.calendar_today, '${matchDate.day}/${matchDate.month}/${matchDate.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: matchTime);
                          if (t != null) {
                            setStateDialog(() {
                              matchTime = t;
                              matchDate = DateTime(matchDate.year, matchDate.month, matchDate.day, t.hour, t.minute);
                            });
                          }
                        },
                        child: _infoBox(Icons.access_time, '${matchTime.hour.toString().padLeft(2, '0')}:${matchTime.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Lieu
                TextField(
                  controller: lieuController,
                  decoration: InputDecoration(labelText: 'Lieu', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 16),
                // Phase
                DropdownButtonFormField<String>(
                  value: _phases.contains(matchPhase) ? matchPhase : 'Phase de Groupes',
                  decoration: InputDecoration(labelText: 'Phase', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _phases.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setStateDialog(() => matchPhase = val!),
                ),
                const SizedBox(height: 16),
                // Statut
                DropdownButtonFormField<String>(
                  value: matchStatut,
                  decoration: InputDecoration(labelText: 'Statut', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: statuts.map((s) => DropdownMenuItem(value: s, child: Text(
                    s == 'A_VENIR' ? 'A venir' : s == 'EN_COURS' ? 'En cours' : s == 'MI_TEMPS' ? 'Mi-temps' : 'Termine',
                  ))).toList(),
                  onChanged: (val) => setStateDialog(() => matchStatut = val!),
                ),
                const SizedBox(height: 16),
                // Scores (toujours visibles)
                Row(
                  children: [
                    Expanded(child: TextField(controller: scoreAController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Score ASC', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('—', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    Expanded(child: TextField(controller: scoreBController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Score ADV', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
            isLoading
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: CircularProgressIndicator(strokeWidth: 2))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A5C36), foregroundColor: Colors.white),
                    onPressed: () async {
                      setStateDialog(() => isLoading = true);
                      try {
                        final Map<String, dynamic> data = {
                          'date_match': matchDate.toIso8601String(),
                          'lieu': lieuController.text,
                          'phase': matchPhase,
                          'statut': matchStatut,
                          'score_asc': int.tryParse(scoreAController.text) ?? 0,
                          'score_adv': int.tryParse(scoreBController.text) ?? 0,
                        };
                        await _ascService.updateSuperAdminMatch(match['id'], data);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        _fetchMatches();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match modifie avec succes'), backgroundColor: Colors.green));
                      } catch (e) {
                        setStateDialog(() => isLoading = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: const Text('Enregistrer'),
                  ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTeamSelectors(List<Map<String, dynamic>> filteredPoules) {
    final teams = (filteredPoules[_selectedPouleIndex!]['teams'] as List<dynamic>? ?? []);
    return [
      const SizedBox(height: 16),
      _sectionTitle('Équipe A'),
      const SizedBox(height: 8),
      _buildDropdown<int>(
        value: _teamAId,
        hint: 'Sélectionner l\'équipe A',
        icon: Icons.shield,
        items: teams.map<DropdownMenuItem<int>>((t) {
          return DropdownMenuItem(value: t['id'] as int, child: Text(t['nom_equipe'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)));
        }).toList(),
        onChanged: (val) => setState(() => _teamAId = val),
      ),
      const SizedBox(height: 12),
      const Center(child: Text('⚔️ VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)))),
      const SizedBox(height: 12),
      _sectionTitle('Équipe B'),
      const SizedBox(height: 8),
      _buildDropdown<int>(
        value: _teamBId,
        hint: 'Sélectionner l\'équipe B',
        icon: Icons.shield_outlined,
        items: teams.where((t) => (t['id'] as int) != _teamAId).map<DropdownMenuItem<int>>((t) {
          return DropdownMenuItem(value: t['id'] as int, child: Text(t['nom_equipe'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)));
        }).toList(),
        onChanged: (val) => setState(() => _teamBId = val),
      ),
      const SizedBox(height: 16),
    ];
  }

  // ─── HELPER WIDGETS ───

  Widget _buildCatBtn(String cat, String label, Color color) {
    final selected = _categorie == cat;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_categorie != cat) {
            setState(() {
              _categorie = cat;
              _selectedPouleIndex = null;
              _teamAId = null;
              _teamBId = null;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : Colors.grey[300]!),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.grey[600])),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36)));
  }

  Widget _buildDropdown<T>({T? value, required String hint, required IconData icon, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[300]!)),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF0A5C36)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _infoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0A5C36)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
