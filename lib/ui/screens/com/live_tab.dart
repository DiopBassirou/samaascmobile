import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/match_provider.dart';
import '../../../providers/player_provider.dart';
import '../../widgets/team_logo.dart';
import '../../../providers/poule_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/match_model.dart';

class LiveTab extends StatefulWidget {
  const LiveTab({super.key});

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userRole = auth.user?['role']?['nom']?.toString().toLowerCase() ?? '';
    final isCom = userRole.contains('com') || userRole.contains('charge');

    return Consumer3<MatchProvider, PlayerProvider, PouleProvider>(
      builder: (context, matchProv, playerProv, pouleProv, child) {
        final currentMatch = matchProv.currentMatch;
        final nextMatch = matchProv.nextMatch;
        final lastMatch = matchProv.lastMatch;
        final match = currentMatch ?? nextMatch ?? lastMatch;

        if (matchProv.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Management Button (Seulement pour Chargé de Com)
              if (isCom)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A5C36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.event_available, size: 20),
                      label: const Text('Programmer un Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () => _showMatchDialog(context, auth, pouleProv, matchProv),
                    ),
                  ),
                ),

              if (match == null) ...[
                _buildEmptyState(),
              ] else ...[
                // Score Board Container
                _buildScoreBoard(context, auth, matchProv, match, isCom),
                const SizedBox(height: 20),

                // Section Actions Direct (Seulement si Chargé de Com & Match EN_COURS ou MI_TEMPS)
                if (isCom && (match.statut == 'EN_COURS' || match.statut == 'MI_TEMPS')) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A5C36).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.gamepad, color: Color(0xFF0A5C36), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text('Contrôle du Direct', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Goals row
                        Row(
                          children: [
                            Expanded(
                              child: _buildPremiumButton(
                                '⚽ Notre ASC',
                                const Color(0xFF2E7D32),
                                Icons.sports_soccer,
                                () => _showAddGoalDialog(context, auth, matchProv, playerProv, match, true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildPremiumButton(
                                '⚽ Adversaire',
                                const Color(0xFFC62828),
                                Icons.sports_soccer,
                                () => _showAddGoalDialog(context, auth, matchProv, playerProv, match, false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Status row
                        Row(
                          children: [
                            if (match.statut == 'EN_COURS')
                              Expanded(
                                child: _buildPremiumButton(
                                  '⏸ Mi-Temps',
                                  const Color(0xFFE65100),
                                  Icons.pause_circle_filled,
                                  () async {
                                    try {
                                      await matchProv.updateMatchStatus(auth, match.id, 'MI_TEMPS');
                                      await matchProv.addMatchEvent(auth, match.id, 'MI_TEMPS', minute: 45, description: 'Sifflet de la mi-temps');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('⏸ Mi-temps sifflée !'), backgroundColor: Colors.orange),
                                        );
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
                              )
                            else
                              Expanded(
                                child: _buildPremiumButton(
                                  '▶ 2ème MT',
                                  const Color(0xFF2E7D32),
                                  Icons.play_circle_fill,
                                  () async {
                                    try {
                                      await matchProv.updateMatchStatus(auth, match.id, 'EN_COURS');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('▶ 2ème mi-temps lancée !'), backgroundColor: Colors.green),
                                        );
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
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildPremiumButton(
                                '🏁 Sifflet Final',
                                const Color(0xFF212121),
                                Icons.flag,
                                () async {
                                  // Confirmer avant de terminer
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('🏁 Sifflet Final ?'),
                                      content: Text('Confirmer la fin du match ?\n\nScore final : Notre ASC ${match.scoreAsc ?? 0} - ${match.scoreAdv ?? 0} ${match.opponentName}'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF212121)),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Terminer le Match', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await matchProv.updateMatchStatus(auth, match.id, 'TERMINE');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('🏁 Match Terminé ! Classement recalculé.'), backgroundColor: Color(0xFF2E7D32)),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Timeline / Events Chronology
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timeline, color: Color(0xFF0A5C36), size: 20),
                          const SizedBox(width: 8),
                          const Text('Fil du Match', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${match.events.length} événement(s)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildEventsTimeline(match.events),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.sports_soccer, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun match enregistré', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Utilisez le bouton ci-dessus pour programmer un match !', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard(BuildContext context, AuthProvider auth, MatchProvider matchProv, MatchGame match, bool isCom) {
    Color badgeColor;
    String badgeText;

    switch (match.statut) {
      case 'EN_COURS':
        badgeColor = Colors.red;
        badgeText = '🔴 EN DIRECT';
        break;
      case 'MI_TEMPS':
        badgeColor = Colors.amber[800]!;
        badgeText = '⏸️ MI-TEMPS';
        break;
      case 'TERMINE':
        badgeColor = Colors.grey[700]!;
        badgeText = '🏁 MATCH TERMINÉ';
        break;
      default:
        badgeColor = const Color(0xFF0F8A4B);
        badgeText = '📅 MATCH À VENIR';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A5C36), Color(0xFF0F8A4B), Color(0xFF14A05E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0A5C36).withValues(alpha: 0.35), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
            child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamLogo(auth.user?['asc']?['nom'] ?? 'Notre ASC', const Color(0xFF66BB6A), logoUrl: auth.user?['asc']?['logo_url']),
              if (match.statut == 'A_VENIR')
                Column(
                  children: [
                    const Text('VS', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w300)),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(match.dateMatch),
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${match.scoreAsc ?? 0} - ${match.scoreAdv ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
              _buildTeamLogo(match.opponentName, const Color(0xFF42A5F5)),
            ],
          ),
          if (isCom && match.statut == 'A_VENIR') ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A5C36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('DÉMARRER LE MATCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () async {
                  try {
                    await matchProv.updateMatchStatus(auth, match.id, 'EN_COURS');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('⚽ Match démarré !'), backgroundColor: Color(0xFF2E7D32)),
                      );
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
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.hour}h${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildTeamLogo(String name, Color color, {String? logoUrl}) {
    return Column(
      children: [
        TeamLogo(
          teamName: name,
          logoUrl: logoUrl,
          fallbackColor: color,
          size: 52,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 110,
          child: Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildPremiumButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTimeline(List<MatchEvent> events) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('Aucun événement enregistré', style: TextStyle(color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }

    return Column(
      children: events.asMap().entries.map<Widget>((entry) {
        final e = entry.value;
        final isLast = entry.key == events.length - 1;

        String title = '';
        IconData icon = Icons.sports_soccer;
        Color iconColor = Colors.green;

        if (e.type == 'BUT_ASC') {
          title = '⚽ But Notre ASC${e.playerName != null ? " : ${e.playerName}" : ""}';
          iconColor = const Color(0xFF2E7D32);
        } else if (e.type == 'BUT_ADV') {
          title = '⚽ But Adversaire';
          iconColor = const Color(0xFFC62828);
        } else if (e.type == 'MI_TEMPS') {
          title = '⏸️ Mi-Temps';
          icon = Icons.pause_circle_filled;
          iconColor = Colors.amber[800]!;
        } else if (e.type == 'CARTON') {
          title = '🟨 Carton';
          icon = Icons.square;
          iconColor = Colors.amber;
        }

        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (e.description != null && e.description!.isNotEmpty)
                      Text(e.description!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text("${e.minute}'", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Dialog pour enregistrer un but (buteur & minute)
  void _showAddGoalDialog(BuildContext context, AuthProvider auth, MatchProvider matchProv, PlayerProvider playerProv, MatchGame match, bool isAsc) {
    int? selectedPlayerId = playerProv.players.isNotEmpty ? playerProv.players.first.id : null;
    final minuteController = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.sports_soccer, color: isAsc ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
                  const SizedBox(width: 8),
                  Text(isAsc ? 'But Notre ASC' : 'But Adversaire', style: TextStyle(color: isAsc ? const Color(0xFF2E7D32) : const Color(0xFFC62828), fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAsc) ...[
                    const Text('Buteur :', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedPlayerId,
                      isExpanded: true,
                      items: playerProv.players.map((p) {
                        return DropdownMenuItem<int>(
                          value: p.id,
                          child: Text('${p.nom} (${p.poste})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedPlayerId = val),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
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
                    final playerName = isAsc && selectedPlayerId != null
                        ? playerProv.players.where((p) => p.id == selectedPlayerId).firstOrNull?.nom
                        : null;
                    try {
                      await matchProv.addMatchEvent(
                        auth,
                        match.id,
                        isAsc ? 'BUT_ASC' : 'BUT_ADV',
                        playerId: isAsc ? selectedPlayerId : null,
                        minute: minute,
                        description: isAsc ? 'But de ${playerName ?? "Notre ASC"} ($minute\')' : 'But adverse ($minute\')',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAsc ? '⚽ But Notre ASC ! Score : ${(match.scoreAsc ?? 0) + 1}-${match.scoreAdv ?? 0}' : '⚽ But Adversaire ! Score : ${match.scoreAsc ?? 0}-${(match.scoreAdv ?? 0) + 1}'),
                            backgroundColor: isAsc ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          ),
                        );
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
      },
    );
  }

  // Dialog premium pour programmer un match
  void _showMatchDialog(BuildContext context, AuthProvider auth, PouleProvider pouleProv, MatchProvider matchProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _MatchSheet(auth: auth, pouleProv: pouleProv, matchProv: matchProv);
      },
    );
  }
}

/// Sheet premium pour programmer match
class _MatchSheet extends StatefulWidget {
  final AuthProvider auth;
  final PouleProvider pouleProv;
  final MatchProvider matchProv;

  const _MatchSheet({required this.auth, required this.pouleProv, required this.matchProv});

  @override
  State<_MatchSheet> createState() => _MatchSheetState();
}

class _MatchSheetState extends State<_MatchSheet> {

  int? _selectedPouleIndex;
  int? _selectedTeamId;
  DateTime _matchDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _matchTime = const TimeOfDay(hour: 16, minute: 0);

  String _matchCategorie = 'SENIOR';

  // Match : lieu et phase
  final _lieuController = TextEditingController();
  String _matchPhase = 'Phase de Groupes';
  static const _phases = ['Phase de Groupes', '1/4 Finale', '1/2 Finale', 'Finale', 'Match Amical'];

  @override
  void initState() {
    super.initState();
    // Fetch poules on open
    if (widget.pouleProv.poules.isEmpty) {
      widget.pouleProv.fetchPoules(widget.auth);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 45, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0A5C36), Color(0xFF0F8A4B)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF0A5C36).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.event, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Programmer un Match', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text('Configurez votre prochaine rencontre', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 28),
                  color: Colors.grey[600],
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildCreateMatchTab(),
          ),
        ],
      ),
    );
  }



  Widget _buildCreateMatchTab() {
    final poules = widget.pouleProv.poules;

    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (poules.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Aucune poule trouvée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    Text('Demandez à l\'admin de créer une poule.', style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Sélection poule
            const Text('Poule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonFormField<int>(
                value: _selectedPouleIndex,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.emoji_events_outlined, color: Color(0xFF0A5C36)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintText: 'Sélectionner une poule',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                items: List.generate(poules.length, (i) {
                  return DropdownMenuItem<int>(
                    value: i,
                    child: Text(poules[i]['nom'] ?? 'Poule ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }),
                onChanged: (val) {
                  setState(() {
                    _selectedPouleIndex = val;
                    _selectedTeamId = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Sélection adversaire
            if (_selectedPouleIndex != null) ...[
              const Text('Adversaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedTeamId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF0A5C36)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Sélectionner l\'équipe adverse',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  items: (poules[_selectedPouleIndex!]['teams'] as List<dynamic>? ?? []).map((t) {
                    return DropdownMenuItem<int>(
                      value: t['id'],
                      child: Text(t['nom_equipe'] ?? 'Équipe', style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTeamId = val),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Catégorie du match
            const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _matchCategorie = 'SENIOR'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _matchCategorie == 'SENIOR' ? const Color(0xFF0A5C36) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _matchCategorie == 'SENIOR' ? const Color(0xFF0A5C36) : Colors.grey[300]!),
                      ),
                      child: Center(child: Text('🧑 Seniors', style: TextStyle(fontWeight: FontWeight.bold, color: _matchCategorie == 'SENIOR' ? Colors.white : Colors.grey[600]))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _matchCategorie = 'CADET'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _matchCategorie == 'CADET' ? const Color(0xFF0F8A4B) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _matchCategorie == 'CADET' ? const Color(0xFF0F8A4B) : Colors.grey[300]!),
                      ),
                      child: Center(child: Text('🏃 Cadets', style: TextStyle(fontWeight: FontWeight.bold, color: _matchCategorie == 'CADET' ? Colors.white : Colors.grey[600]))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Phase de la compétition
            const Text('Phase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
              child: DropdownButtonFormField<String>(
                value: _matchPhase,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.workspaces_outline, color: Color(0xFF0A5C36)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _phases.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                onChanged: (val) => setState(() => _matchPhase = val ?? 'Phase de Groupes'),
              ),
            ),
            const SizedBox(height: 20),

            // Lieu du match
            const Text('Terrain / Lieu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
            const SizedBox(height: 8),
            TextField(
              controller: _lieuController,
              decoration: InputDecoration(
                hintText: 'Ex: Terrain HLM, Stade Léopold Sédar...',
                prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0A5C36)),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2)),
              ),
            ),
            const SizedBox(height: 20),

            // Date et Heure du Match
            const Text('Date et Heure du Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final dt = await showDatePicker(
                        context: context,
                        initialDate: _matchDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF0A5C36)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (dt != null) setState(() => _matchDate = dt);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFF0A5C36), size: 20),
                          const SizedBox(width: 10),
                          Text('${_matchDate.day}/${_matchDate.month}/${_matchDate.year}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final tm = await showTimePicker(
                        context: context,
                        initialTime: _matchTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF0A5C36)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (tm != null) setState(() => _matchTime = tm);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_outlined, color: Color(0xFF0A5C36), size: 20),
                          const SizedBox(width: 10),
                          Text(_matchTime.format(context), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5C36),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF0A5C36).withValues(alpha: 0.4),
                ),
                onPressed: _selectedPouleIndex == null || _selectedTeamId == null
                    ? null
                    : () async {
                        final dt = DateTime(
                          _matchDate.year, _matchDate.month, _matchDate.day,
                          _matchTime.hour, _matchTime.minute,
                        );

                        try {
                          await widget.matchProv.createMatch(
                            widget.auth,
                            _selectedTeamId!,
                            dt.toIso8601String(),
                            categorie: _matchCategorie,
                            lieu: _lieuController.text.trim(),
                            phase: _matchPhase,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('📅 Match programmé avec succès !'), backgroundColor: Color(0xFF2E7D32)),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Programmer le Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
