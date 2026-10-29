import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/poule_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/asc_provider.dart';
import '../../../services/asc_service.dart';
import '../../../models/match_model.dart';
import '../../../providers/match_provider.dart';
import 'super_admin_live_screen.dart';

class SuperAdminMatchesTab extends StatefulWidget {
  const SuperAdminMatchesTab({super.key});

  @override
  State<SuperAdminMatchesTab> createState() => _SuperAdminMatchesTabState();
}

class _SuperAdminMatchesTabState extends State<SuperAdminMatchesTab> {
  final AscService _ascService = AscService();

  String _categorie = 'SENIOR';
  int? _selectedPouleIndex;
  String? _teamAKey;
  String? _teamBKey;

  DateTime _matchDate = DateTime.now();
  TimeOfDay _matchTime = const TimeOfDay(hour: 16, minute: 0);
  final _lieuController = TextEditingController();
  String _matchPhase = 'Phase de Groupes';
  static const _phases = [
    'Phase de Groupes',
    '1/32 Finale',
    '1/16 Finale',
    '1/8 Finale',
    '1/4 Finale',
    '1/2 Finale',
    'Finale',
    'Match Amical',
  ];

  String _selectedCoupeType = 'Coupe Zonale';
  static const _coupeTypes = [
    'Coupe Zonale',
    'Coupe Communale',
    'Coupe Départementale',
    'Coupe Régionale',
  ];

  // Score direct (optionnel)
  bool _hasScore = false;
  final _scoreAController = TextEditingController(text: '0');
  final _scoreBController = TextEditingController(text: '0');
  
  bool _hasPenalties = false;
  final _penaltiesAController = TextEditingController();
  final _penaltiesBController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingMatches = false;
  bool _isLoadingAscs = false;
  List<Map<String, dynamic>> _allMatches = [];
  List<Map<String, dynamic>> _allAscs = [];
  String _matchStatusFilter = 'A_VENIR'; // 'A_VENIR' ou 'TERMINE'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final pouleProv = Provider.of<PouleProvider>(context, listen: false);
      final ascProv = Provider.of<AscProvider>(context, listen: false);
      pouleProv.fetchPoules(auth);
      ascProv.fetchSuperAdminAscs();
    });
    _loadAscs();
    _fetchMatches();
  }

  Future<void> _loadAscs() async {
    setState(() => _isLoadingAscs = true);
    try {
      final ascProv = Provider.of<AscProvider>(context, listen: false);
      await ascProv.fetchSuperAdminAscs();
      if (mounted && ascProv.ascs.isNotEmpty) {
        setState(() => _allAscs = ascProv.ascs);
      }
    } catch (_) {
      try {
        final ascs = await _ascService.getSuperAdminAscs();
        if (mounted) setState(() => _allAscs = ascs);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isLoadingAscs = false);
    }
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

  List<Map<String, dynamic>> _getSelectableTeams(List<Map<String, dynamic>> filteredPoules, List<Map<String, dynamic>> currentAscs) {
    final List<Map<String, dynamic>> teams = [];
    final Set<String> addedKeys = {};

    // 1. Ajouter toutes les ASCs enregistrées sur la plateforme (y compris les nouvelles créées sans poule)
    for (var asc in currentAscs) {
      final code = asc['code_unique']?.toString() ?? '';
      if (code.isNotEmpty) {
        final key = 'asc:$code';
        addedKeys.add(key);

        String subtitle = '';
        int? pouleTeamId;
        for (var p in filteredPoules) {
          if (p['teams'] != null) {
            for (var t in p['teams']) {
              if (t['asc_code'] == code) {
                pouleTeamId = t['id'];
                final zoneText = asc['zone'] != null ? ' • ${asc['zone']}' : '';
                subtitle = '${p['nom']}$zoneText';
                break;
              }
            }
          }
          if (pouleTeamId != null) break;
        }

        // Si l'équipe ne fait partie d'aucune poule (ex: Coupe Départementale, Coupe Régionale, Amical)
        if (subtitle.isEmpty) {
          subtitle = asc['zone'] != null ? 'Zone: ${asc['zone']} • Hors poule' : 'Hors poule';
        }

        teams.add({
          'key': key,
          'asc_code': code,
          'poule_team_id': pouleTeamId,
          'nom': asc['nom'] ?? 'ASC Sans nom',
          'subtitle': subtitle,
          'logo': asc['logo_url'],
        });
      }
    }

    // 2. Ajouter les équipes de poules qui n'étaient pas dans currentAscs
    for (var p in filteredPoules) {
      if (p['teams'] != null) {
        for (var t in p['teams']) {
          final ascCode = t['asc_code']?.toString();
          final id = t['id'];
          final key = ascCode != null && ascCode.isNotEmpty ? 'asc:$ascCode' : 'poule:$id';
          if (!addedKeys.contains(key)) {
            addedKeys.add(key);
            teams.add({
              'key': key,
              'asc_code': ascCode,
              'poule_team_id': id,
              'nom': t['nom_equipe'] ?? 'Équipe',
              'subtitle': '${p['nom']}',
              'logo': t['logo'],
            });
          }
        }
      }
    }

    teams.sort((a, b) => (a['nom'] as String).toLowerCase().compareTo((b['nom'] as String).toLowerCase()));
    return teams;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PouleProvider, AscProvider>(
      builder: (context, pouleProv, ascProv, _) {
        final currentAscs = ascProv.ascs.isNotEmpty ? ascProv.ascs : _allAscs;
        final filteredPoules = pouleProv.poules.where((p) => p['categorie'] == _categorie).toList();
        final selectableTeams = _getSelectableTeams(filteredPoules.cast<Map<String, dynamic>>(), currentAscs);
        
        final displayedMatches = _allMatches.where((m) {
          final isSameCategory = m['categorie'] == _categorie;
          bool isSameStatus = false;
          final st = m['statut'];
          if (_matchStatusFilter == 'TERMINE') {
            isSameStatus = (st == 'TERMINE');
          } else if (_matchStatusFilter == 'EN_COURS') {
            isSameStatus = (st == 'EN_COURS' || st == 'MI_TEMPS' || st == 'DEUXIEME_MI_TEMPS' || st == 'TIR_AU_BUT');
          } else {
            // A_VENIR ou autre
            isSameStatus = (st != 'TERMINE' && st != 'EN_COURS' && st != 'MI_TEMPS' && st != 'DEUXIEME_MI_TEMPS' && st != 'TIR_AU_BUT');
          }
          return isSameCategory && isSameStatus;
        }).toList();

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await Future.wait([
                pouleProv.fetchPoules(auth),
                ascProv.fetchSuperAdminAscs(),
                _fetchMatches(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      children: [
                        const Icon(Icons.sports_soccer, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Création Rapide de Matchs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Programmez ou enregistrez les résultats', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'Actualiser les équipes',
                          onPressed: () {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            pouleProv.fetchPoules(auth);
                            ascProv.fetchSuperAdminAscs();
                            _loadAscs();
                            _fetchMatches();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Données actualisées'), duration: Duration(seconds: 1)),
                            );
                          },
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

                  // ─── ÉQUIPES ───
                  if (selectableTeams.isEmpty)
                    _emptyBox('Aucune équipe ou ASC disponible')
                  else ...[
                    ..._buildTeamSelectors(selectableTeams),

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

                  // ─── TYPE DE COUPE ───
                  _sectionTitle('Type de Coupe'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: _selectedCoupeType,
                    hint: 'Type de Coupe',
                    icon: Icons.emoji_events_outlined,
                    items: _coupeTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCoupeType = val ?? 'Coupe Zonale'),
                  ),
                  const SizedBox(height: 16),

                  // ─── SCORE DIRECT ───
                  SwitchListTile(
                    title: const Text('Match déjà joué ? (Score direct)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Activez pour saisir le score final maintenant'),
                    value: _hasScore,
                    activeThumbColor: const Color(0xFF0A5C36),
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
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Match terminé aux tirs au but ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: _hasPenalties,
                      activeThumbColor: const Color(0xFF0A5C36),
                      onChanged: (val) => setState(() => _hasPenalties = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_hasPenalties) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _penaltiesAController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: 'TAB Éq. A',
                                filled: true,
                                fillColor: Colors.green.withValues(alpha: 0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('TAB', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _penaltiesBController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: 'TAB Éq. B',
                                filled: true,
                                fillColor: Colors.red.withValues(alpha: 0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                            color: _matchStatusFilter == 'A_VENIR' ? Colors.blue : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text('Programmés', style: TextStyle(color: _matchStatusFilter == 'A_VENIR' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _matchStatusFilter = 'EN_COURS'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _matchStatusFilter == 'EN_COURS' ? Colors.red : Colors.grey[200],
                          ),
                          alignment: Alignment.center,
                          child: Text('En Direct', style: TextStyle(color: _matchStatusFilter == 'EN_COURS' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _matchStatusFilter = 'TERMINE'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _matchStatusFilter == 'TERMINE' ? const Color(0xFF0A5C36) : Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text('Terminés', style: TextStyle(color: _matchStatusFilter == 'TERMINE' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
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
                    return _buildMatchCard(match);
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final statut = match['statut'] ?? 'A_VENIR';
    final isTermine = statut == 'TERMINE';
    final isLive = statut == 'EN_COURS' || statut == 'MI_TEMPS' || statut == 'DEUXIEME_MI_TEMPS' || statut == 'TIR_AU_BUT';
    final isReporte = statut == 'REPORTE';

    // Noms des équipes
    final String homeTeam = match['team_a_name'] ?? match['asc']?['nom'] ?? match['asc_code'] ?? '?';
    final String awayTeam = match['team_b_name'] ?? match['opponent']?['nom_equipe'] ?? match['opponent']?['asc']?['nom'] ?? match['adversaire_nom'] ?? '?';
    
    // Logos
    final String? homeLogo = match['team_a_logo'] ?? match['asc']?['logo_url'];
    final String? awayLogo = match['team_b_logo'] ?? match['opponent']?['logo'] ?? match['opponent']?['asc']?['logo_url'];

    // Date
    String dateLabel = '';
    String timeLabel = '';
    if (match['date_match'] != null) {
      try {
        final dt = DateTime.parse(match['date_match']);
        dateLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    // Couleur et label du statut
    Color statutColor;
    String statutLabel;
    if (isTermine) {
      statutColor = const Color(0xFF0A5C36);
      statutLabel = 'Terminé';
    } else if (isLive) {
      statutColor = Colors.red;
      statutLabel = statut == 'MI_TEMPS' ? 'Mi-temps' : statut == 'DEUXIEME_MI_TEMPS' ? '2ème MT' : 'En cours';
    } else if (isReporte) {
      statutColor = Colors.orange[800]!;
      statutLabel = 'Reporté';
    } else {
      statutColor = Colors.blue;
      statutLabel = 'Programmé';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ─── Header : Statut + Phase + Date ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statutColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive) ...[
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                      ],
                      Text(statutLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Phase
                if (match['phase'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(match['phase'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  ),
                // Type de Coupe
                if (match['type_coupe'] != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A5C36).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0A5C36).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      match['type_coupe'],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)),
                    ),
                  ),
                ],
                const Spacer(),
                // Date + Heure
                if (dateLabel.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('$dateLabel  $timeLabel', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
              ],
            ),
          ),

          // ─── Corps : Équipes + Score ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Équipe A (Home)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _teamLogo(homeTeam, homeLogo, const Color(0xFF0A5C36)),
                      const SizedBox(height: 8),
                      Text(
                        homeTeam,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Score
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isLive
                          ? Colors.red.withValues(alpha: 0.08)
                          : isTermine
                              ? const Color(0xFF0A5C36).withValues(alpha: 0.06)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: isLive ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5) : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${match['score_asc'] ?? 0} - ${match['score_adv'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: isLive ? Colors.red : isTermine ? const Color(0xFF1B5E20) : Colors.grey[400],
                          ),
                        ),
                        if (isLive)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(statutLabel, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (!isTermine && !isLive && timeLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(timeLabel, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ),
                // Équipe B (Away)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _teamLogo(awayTeam, awayLogo, const Color(0xFFC62828)),
                      const SizedBox(height: 8),
                      Text(
                        awayTeam,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ─── Actions Rapides (En Direct) ───
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                border: Border(top: BorderSide(color: Colors.red.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.sports_soccer, size: 16),
                      label: Text('But $homeTeam', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      onPressed: () => _showQuickAddGoalDialog(match, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.sports_soccer, size: 16),
                      label: Text('But $awayTeam', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      onPressed: () => _showQuickAddGoalDialog(match, false),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Footer : Lieu + Actions ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Lieu
                if (match['lieu'] != null && match['lieu'].toString().isNotEmpty) ...[
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      match['lieu'],
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                // Boutons d'action
                if (statut != 'TERMINE' && statut != 'REPORTE')
                  _actionButton(Icons.live_tv, 'Live', Colors.orange, () {
                    final matchModel = MatchGame.fromJson(match);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SuperAdminLiveScreen(match: matchModel)));
                  }),
                const SizedBox(width: 6),
                _actionButton(Icons.edit, 'Modifier', Colors.blue, () => _showEditMatchDialog(match)),
                const SizedBox(width: 6),
                _actionButton(Icons.delete_outline, 'Suppr.', Colors.red, () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer ce match ?'),
                      content: Text('$homeTeam vs $awayTeam'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await _ascService.deleteSuperAdminMatch(match['id']);
                      setState(() {
                        _allMatches.removeWhere((element) => element['id'] == match['id']);
                      });
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match supprimé'), backgroundColor: Colors.green));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                    }
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamLogo(String name, String? logoUrl, Color fallbackColor) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[100],
        backgroundImage: NetworkImage(logoUrl),
      );
    }
    // Fallback : initiales dans un cercle
    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: fallbackColor.withValues(alpha: 0.12),
      child: Text(initials, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: fallbackColor)),
    );
  }

  void _showQuickAddGoalDialog(Map<String, dynamic> matchData, bool isAsc) {
    final match = MatchGame.fromJson(matchData);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final matchProv = Provider.of<MatchProvider>(context, listen: false);
    
    final minuteController = TextEditingController(text: '');
    final manualNameController = TextEditingController(text: '');
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.sports_soccer, color: isAsc ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
              const SizedBox(width: 8),
              Text(isAsc ? 'But ${match.teamAName}' : 'But ${match.teamBName}', style: TextStyle(color: isAsc ? const Color(0xFF2E7D32) : const Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nom ou Numéro du Buteur :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: manualNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'ex: Moussa (9)',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Minute du but :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: minuteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'ex: 24',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAsc ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Valider'),
              onPressed: () async {
                final minute = int.tryParse(minuteController.text) ?? 1;
                final playerName = manualNameController.text.trim().isNotEmpty ? manualNameController.text.trim() : null;
                
                try {
                  await matchProv.superAdminAddEvent(
                    auth,
                    match.id,
                    isAsc ? 'BUT_ASC' : 'BUT_ADV',
                    playerName: playerName,
                    minute: minute,
                    description: isAsc ? 'But de ${playerName ?? match.teamAName} ($minute\')' : 'But de ${match.teamBName} ($minute\')',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('⚽ But enregistré !'),
                        backgroundColor: isAsc ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    );
                    _fetchMatches(); // Refresh the list
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMatch() async {
    if (_teamAKey == null || _teamBKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les 2 équipes'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_teamAKey == _teamBKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les 2 équipes doivent être différentes'), backgroundColor: Colors.red),
      );
      return;
    }

    int? pouleTeamAId;
    String? ascCodeA;
    if (_teamAKey!.startsWith('asc:')) {
      ascCodeA = _teamAKey!.substring(4);
    } else if (_teamAKey!.startsWith('poule:')) {
      pouleTeamAId = int.tryParse(_teamAKey!.substring(6));
    }

    int? pouleTeamBId;
    String? ascCodeB;
    if (_teamBKey!.startsWith('asc:')) {
      ascCodeB = _teamBKey!.substring(4);
    } else if (_teamBKey!.startsWith('poule:')) {
      pouleTeamBId = int.tryParse(_teamBKey!.substring(6));
    }

    setState(() => _isSubmitting = true);

    final dateTime = DateTime(
      _matchDate.year, _matchDate.month, _matchDate.day,
      _matchTime.hour, _matchTime.minute,
    );

    try {
      final result = await _ascService.createSuperAdminMatch(
        pouleTeamAId: pouleTeamAId,
        pouleTeamBId: pouleTeamBId,
        ascCodeA: ascCodeA,
        ascCodeB: ascCodeB,
        dateMatch: dateTime.toIso8601String(),
        categorie: _categorie,
        lieu: _lieuController.text.trim().isEmpty ? null : _lieuController.text.trim(),
        phase: _matchPhase,
        typeCoupe: _selectedCoupeType,
        scoreA: _hasScore ? int.tryParse(_scoreAController.text) : null,
        scoreB: _hasScore ? int.tryParse(_scoreBController.text) : null,
        penaltiesA: _hasPenalties ? (int.tryParse(_penaltiesAController.text) ?? 0) : null,
        penaltiesB: _hasPenalties ? (int.tryParse(_penaltiesBController.text) ?? 0) : null,
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
        _teamAKey = null;
        _teamBKey = null;
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
    String matchCoupeType = _coupeTypes.contains(match['type_coupe']) ? match['type_coupe'] : 'Coupe Zonale';
    
    final scoreAController = TextEditingController(text: (match['score_asc'] ?? 0).toString());
    final scoreBController = TextEditingController(text: (match['score_adv'] ?? 0).toString());
    
    final penaltiesAController = TextEditingController(text: (match['penalties_asc'] ?? '').toString());
    final penaltiesBController = TextEditingController(text: (match['penalties_adv'] ?? '').toString());
    
    // Statut modifiable
    const statuts = ['A_VENIR', 'EN_COURS', 'MI_TEMPS', 'DEUXIEME_MI_TEMPS', 'TIR_AU_BUT', 'TERMINE', 'REPORTE'];
    String matchStatut = statuts.contains(match['statut']) ? match['statut'] : 'A_VENIR';
    
    bool isLoading = false;
    
    // Recuperer toutes les equipes de la meme categorie
    final pouleProv = Provider.of<PouleProvider>(context, listen: false);
    final ascProv = Provider.of<AscProvider>(context, listen: false);
    final ascsList = ascProv.ascs.isNotEmpty ? ascProv.ascs : _allAscs;
    final categoryPoules = pouleProv.poules.where((p) => p['categorie'] == match['categorie']).toList();
    final allTeams = _getSelectableTeams(categoryPoules.cast<Map<String, dynamic>>(), ascsList);
    
    String? teamAKey;
    String? teamBKey;

    if (match['asc_code'] != null) {
      teamAKey = 'asc:${match['asc_code']}';
    }
    if (match['adversaire_code'] != null) {
      teamBKey = 'asc:${match['adversaire_code']}';
    } else if (match['opponent']?['id'] != null) {
      teamBKey = 'poule:${match['opponent']['id']}';
    }

    if (teamAKey != null && !allTeams.any((t) => t['key'] == teamAKey)) {
      teamAKey = null;
    }
    if (teamBKey != null && !allTeams.any((t) => t['key'] == teamBKey)) {
      teamBKey = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Modifier Match', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Equipes
                if (allTeams.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: teamAKey,
                    decoration: InputDecoration(labelText: 'Équipe A', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: allTeams.map((t) {
                      final subtitle = t['subtitle']?.toString() ?? '';
                      final label = subtitle.isNotEmpty ? '${t['nom']} ($subtitle)' : '${t['nom']}';
                      return DropdownMenuItem<String>(
                        value: t['key'] as String,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setStateDialog(() => teamAKey = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: teamBKey,
                    decoration: InputDecoration(labelText: 'Équipe B', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: allTeams.where((t) => t['key'] != teamAKey).map((t) {
                      final subtitle = t['subtitle']?.toString() ?? '';
                      final label = subtitle.isNotEmpty ? '${t['nom']} ($subtitle)' : '${t['nom']}';
                      return DropdownMenuItem<String>(
                        value: t['key'] as String,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setStateDialog(() => teamBKey = val),
                  ),
                  const SizedBox(height: 16),
                ],
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
                  initialValue: _phases.contains(matchPhase) ? matchPhase : 'Phase de Groupes',
                  decoration: InputDecoration(labelText: 'Phase', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _phases.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setStateDialog(() => matchPhase = val!),
                ),
                const SizedBox(height: 16),
                // Type de Coupe
                DropdownButtonFormField<String>(
                  initialValue: matchCoupeType,
                  decoration: InputDecoration(labelText: 'Type de Coupe', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _coupeTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setStateDialog(() => matchCoupeType = val!),
                ),
                const SizedBox(height: 16),
                // Statut
                DropdownButtonFormField<String>(
                  initialValue: matchStatut,
                  decoration: InputDecoration(labelText: 'Statut', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: statuts.map((s) => DropdownMenuItem(value: s, child: Text(
                    s == 'A_VENIR' ? 'A venir' : s == 'EN_COURS' ? 'En cours (1ère MT)' : s == 'MI_TEMPS' ? 'Mi-temps' : s == 'DEUXIEME_MI_TEMPS' ? 'En cours (2ème MT)' : s == 'TIR_AU_BUT' ? 'Tir au But' : s == 'REPORTE' ? 'Reporté' : 'Terminé',
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextField(controller: penaltiesAController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'TAB ASC', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('TAB', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(child: TextField(controller: penaltiesBController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'TAB ADV', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
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
                          'type_coupe': matchCoupeType,
                          'statut': matchStatut,
                          'score_asc': int.tryParse(scoreAController.text) ?? 0,
                          'score_adv': int.tryParse(scoreBController.text) ?? 0,
                          'penalties_asc': (penaltiesAController.text.trim().isEmpty && penaltiesBController.text.trim().isEmpty) ? null : (int.tryParse(penaltiesAController.text) ?? 0),
                          'penalties_adv': (penaltiesAController.text.trim().isEmpty && penaltiesBController.text.trim().isEmpty) ? null : (int.tryParse(penaltiesBController.text) ?? 0),
                        };
                        if (teamAKey != null) {
                          if (teamAKey!.startsWith('asc:')) {
                            data['asc_code_a'] = teamAKey!.substring(4);
                          } else if (teamAKey!.startsWith('poule:')) {
                            data['poule_team_a_id'] = int.tryParse(teamAKey!.substring(6));
                          }
                        }
                        if (teamBKey != null) {
                          if (teamBKey!.startsWith('asc:')) {
                            data['asc_code_b'] = teamBKey!.substring(4);
                          } else if (teamBKey!.startsWith('poule:')) {
                            data['poule_team_b_id'] = int.tryParse(teamBKey!.substring(6));
                          }
                        }
                        
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

  List<Widget> _buildTeamSelectors(List<Map<String, dynamic>> selectableTeams) {
    return [
      const SizedBox(height: 16),
      _sectionTitle('Équipe A'),
      const SizedBox(height: 8),
      _buildDropdown<String>(
        value: _teamAKey,
        hint: 'Sélectionner l\'équipe A',
        icon: Icons.shield,
        items: selectableTeams.map<DropdownMenuItem<String>>((t) {
          final subtitle = t['subtitle']?.toString() ?? '';
          final label = subtitle.isNotEmpty ? '${t['nom']} ($subtitle)' : '${t['nom']}';
          return DropdownMenuItem(
            value: t['key'] as String,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (val) => setState(() {
          _teamAKey = val;
          if (_teamBKey == val) _teamBKey = null;
        }),
      ),
      const SizedBox(height: 12),
      const Center(child: Text('⚔️ VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)))),
      const SizedBox(height: 12),
      _sectionTitle('Équipe B'),
      const SizedBox(height: 8),
      _buildDropdown<String>(
        value: _teamBKey,
        hint: 'Sélectionner l\'équipe B',
        icon: Icons.shield_outlined,
        items: selectableTeams.where((t) => (t['key'] as String) != _teamAKey).map<DropdownMenuItem<String>>((t) {
          final subtitle = t['subtitle']?.toString() ?? '';
          final label = subtitle.isNotEmpty ? '${t['nom']} ($subtitle)' : '${t['nom']}';
          return DropdownMenuItem(
            value: t['key'] as String,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (val) => setState(() => _teamBKey = val),
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
              _teamAKey = null;
              _teamBKey = null;
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
        initialValue: value,
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
