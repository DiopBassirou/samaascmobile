import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/match_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/match_model.dart';
import '../../widgets/team_logo.dart';

class SuperAdminLiveScreen extends StatefulWidget {
  final MatchGame match;

  const SuperAdminLiveScreen({super.key, required this.match});

  @override
  State<SuperAdminLiveScreen> createState() => _SuperAdminLiveScreenState();
}

class _SuperAdminLiveScreenState extends State<SuperAdminLiveScreen> {
  /// Pastilles de la séance de TAB : ✅ réussi (vert) / ❌ raté (rouge), avec séparateur mort subite si >5 tirs.
  Widget _tabShotsRow(List<dynamic> events, String goalType, String missType) {
    final shots = events.where((e) => e.type == goalType || e.type == missType).toList();
    if (shots.isEmpty) {
      return const Text('—', style: TextStyle(color: Colors.white38, fontSize: 13));
    }
    final List<Widget> items = [];
    for (int i = 0; i < shots.length; i++) {
      if (i == 5) {
        items.add(
          Container(
            width: 1.5,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white38,
          ),
        );
      }
      final scored = shots[i].type == goalType;
      items.add(
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: scored ? Colors.greenAccent.withValues(alpha: 0.25) : Colors.redAccent.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: scored ? Colors.greenAccent : Colors.redAccent, width: 1.5),
          ),
          child: Icon(scored ? Icons.check : Icons.close, size: 11, color: scored ? Colors.greenAccent : Colors.redAccent),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items,
      ),
    );
  }

  void _tabFeedback(BuildContext context, bool scored, String teamName) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          backgroundColor: scored ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          content: Text(
            scored ? '✅ Tir réussi : $teamName' : '❌ Tir raté : $teamName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
  }

  void _showSuperAdminAddGoalDialog(BuildContext context, AuthProvider auth, MatchProvider matchProv, MatchGame match, bool isAsc) {
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Direct', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0A1929),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<MatchProvider>(
        builder: (context, matchProv, child) {
          final updatedMatch = matchProv.matches.firstWhere(
            (m) => m.id == widget.match.id,
            orElse: () => widget.match,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Score Board
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0A1929), Color(0xFF0D2B45)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(updatedMatch.statut, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              TeamLogo(teamName: updatedMatch.teamAName, logoUrl: updatedMatch.teamALogo, fallbackColor: const Color(0xFF0A5C36), size: 50),
                              const SizedBox(height: 8),
                              Text(updatedMatch.teamAName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('${updatedMatch.scoreAsc ?? 0} - ${updatedMatch.scoreAdv ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                              if (updatedMatch.penaltiesAsc != null && updatedMatch.penaltiesAdv != null)
                                Text('(${updatedMatch.penaltiesAsc} TAB ${updatedMatch.penaltiesAdv})', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              TeamLogo(teamName: updatedMatch.teamBName, logoUrl: updatedMatch.teamBLogo, fallbackColor: const Color(0xFFC62828), size: 50),
                              const SizedBox(height: 8),
                              Text(updatedMatch.teamBName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Contrôles du Direct
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gestion du Match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (updatedMatch.statut == 'A_VENIR')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A5C36),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Démarrer le Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            onPressed: () async {
                              try {
                                await matchProv.superAdminUpdateMatchStatus(auth, updatedMatch.id, 'EN_COURS');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                              }
                            },
                          ),
                        )
                      else if (updatedMatch.statut == 'EN_COURS' || updatedMatch.statut == 'MI_TEMPS' || updatedMatch.statut == 'DEUXIEME_MI_TEMPS' || updatedMatch.statut == 'TIR_AU_BUT')
                        Column(
                          children: [
                            // --- PHASE TIR AU BUT ---
                            if (updatedMatch.statut == 'TIR_AU_BUT') ...[
                              Builder(
                                builder: (context) {
                                  final tabEvents = updatedMatch.events.where((e) =>
                                      e.type == 'TIR_AU_BUT_ASC' || e.type == 'RATE_TAB_ASC' ||
                                      e.type == 'TIR_AU_BUT_ADV' || e.type == 'RATE_TAB_ADV').toList();

                                  final bool isTeamATurn;
                                  final bool isTeamBTurn;
                                  if (tabEvents.isEmpty) {
                                    isTeamATurn = true;
                                    isTeamBTurn = true;
                                  } else {
                                    final lastEvent = tabEvents.last;
                                    final lastWasTeamA = lastEvent.type == 'TIR_AU_BUT_ASC' || lastEvent.type == 'RATE_TAB_ASC';
                                    isTeamATurn = !lastWasTeamA;
                                    isTeamBTurn = lastWasTeamA;
                                  }

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1A237E), Color(0xFF283593)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                    ),
                                    child: Column(
                                      children: [
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.sports_score, color: Colors.amber, size: 24),
                                            SizedBox(width: 8),
                                            Text('🎯 SÉANCE DE TIR AU BUT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                            SizedBox(width: 8),
                                            Icon(Icons.sports_score, color: Colors.amber, size: 24),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Score TAB responsive avec Expanded
                                        Row(
                                          children: [
                                            // Équipe A
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  Text(
                                                    updatedMatch.teamAName,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text('${updatedMatch.penaltiesAsc ?? 0}', style: const TextStyle(color: Colors.greenAccent, fontSize: 38, fontWeight: FontWeight.w900)),
                                                  const SizedBox(height: 6),
                                                  _tabShotsRow(updatedMatch.events, 'TIR_AU_BUT_ASC', 'RATE_TAB_ASC'),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text('TAB', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                            // Équipe B
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  Text(
                                                    updatedMatch.teamBName,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text('${updatedMatch.penaltiesAdv ?? 0}', style: const TextStyle(color: Colors.redAccent, fontSize: 38, fontWeight: FontWeight.w900)),
                                                  const SizedBox(height: 6),
                                                  _tabShotsRow(updatedMatch.events, 'TIR_AU_BUT_ADV', 'RATE_TAB_ADV'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Indicateur de tour
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.sports_soccer, size: 14, color: Colors.amber),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  tabEvents.isEmpty
                                                      ? '👉 Choisissez quelle équipe tire en premier'
                                                      : isTeamATurn
                                                          ? '👉 Au tour de : ${updatedMatch.teamAName}'
                                                          : '👉 Au tour de : ${updatedMatch.teamBName}',
                                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        // Boutons TAB avec Alternance automatique
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isTeamATurn ? const Color(0xFF2E7D32) : Colors.grey[800],
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor: Colors.grey[850],
                                                  disabledForegroundColor: Colors.white30,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                icon: const Icon(Icons.sports_score, size: 18),
                                                label: Text('✅ ${updatedMatch.teamAName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                                onPressed: isTeamATurn ? () async {
                                                  try {
                                                    await matchProv.superAdminAddEvent(auth, updatedMatch.id, 'TIR_AU_BUT_ASC', description: 'Tir au but réussi');
                                                    if (context.mounted) _tabFeedback(context, true, updatedMatch.teamAName);
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                                                    }
                                                  }
                                                } : null,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isTeamBTurn ? const Color(0xFFC62828) : Colors.grey[800],
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor: Colors.grey[850],
                                                  disabledForegroundColor: Colors.white30,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                icon: const Icon(Icons.sports_score, size: 18),
                                                label: Text('✅ ${updatedMatch.teamBName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                                onPressed: isTeamBTurn ? () async {
                                                  try {
                                                    await matchProv.superAdminAddEvent(auth, updatedMatch.id, 'TIR_AU_BUT_ADV', description: 'Tir au but réussi');
                                                    if (context.mounted) _tabFeedback(context, true, updatedMatch.teamBName);
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                                                    }
                                                  }
                                                } : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isTeamATurn ? Colors.grey[700] : Colors.grey[850],
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor: Colors.grey[900],
                                                  disabledForegroundColor: Colors.white24,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                icon: const Icon(Icons.close, size: 18),
                                                label: Text('Raté ${updatedMatch.teamAName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                                onPressed: isTeamATurn ? () async {
                                                  try {
                                                    await matchProv.superAdminAddEvent(auth, updatedMatch.id, 'RATE_TAB_ASC', description: 'Tir au but raté');
                                                    if (context.mounted) _tabFeedback(context, false, updatedMatch.teamAName);
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                                                    }
                                                  }
                                                } : null,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isTeamBTurn ? Colors.grey[700] : Colors.grey[850],
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor: Colors.grey[900],
                                                  disabledForegroundColor: Colors.white24,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                icon: const Icon(Icons.close, size: 18),
                                                label: Text('Raté ${updatedMatch.teamBName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                                                onPressed: isTeamBTurn ? () async {
                                                  try {
                                                    await matchProv.superAdminAddEvent(auth, updatedMatch.id, 'RATE_TAB_ADV', description: 'Tir au but raté');
                                                    if (context.mounted) _tabFeedback(context, false, updatedMatch.teamBName);
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                                                    }
                                                  }
                                                } : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Bouton Annuler le dernier tir
                                        if (tabEvents.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.orangeAccent,
                                                side: const BorderSide(color: Colors.orangeAccent),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                              ),
                                              icon: const Icon(Icons.undo, size: 16),
                                              label: const Text('↩️ Annuler le dernier tir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              onPressed: () async {
                                                try {
                                                  await matchProv.superAdminUndoLastEvent(auth, updatedMatch.id);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('↩️ Dernier tir annulé'), backgroundColor: Colors.orange),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              // Bouton Terminer le Match (après les TAB)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A5C36),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.flag, size: 20),
                                  label: const Text('🏁 Terminer le Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('🏁 Terminer le match ?'),
                                        content: Text('Score : ${updatedMatch.teamAName} ${updatedMatch.scoreAsc ?? 0} - ${updatedMatch.scoreAdv ?? 0} ${updatedMatch.teamBName}\nTAB : ${updatedMatch.penaltiesAsc ?? 0} - ${updatedMatch.penaltiesAdv ?? 0}'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Confirmer'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await matchProv.superAdminUpdateMatchStatus(auth, updatedMatch.id, 'TERMINE');
                                      if (context.mounted) Navigator.pop(context);
                                    }
                                  },
                                ),
                              ),
                            ] else ...[
                              // --- PHASE MATCH NORMAL ---
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPremiumButton(
                                      'But ${updatedMatch.teamAName}',
                                      const Color(0xFF2E7D32),
                                      Icons.sports_soccer,
                                      () => _showSuperAdminAddGoalDialog(context, auth, matchProv, updatedMatch, true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildPremiumButton(
                                      'But ${updatedMatch.teamBName}',
                                      const Color(0xFFC62828),
                                      Icons.sports_soccer,
                                      () => _showSuperAdminAddGoalDialog(context, auth, matchProv, updatedMatch, false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (updatedMatch.statut == 'EN_COURS')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.pause),
                                    label: const Text('Siffler la Mi-Temps'),
                                    onPressed: () => matchProv.superAdminUpdateMatchStatus(auth, updatedMatch.id, 'MI_TEMPS'),
                                  ),
                                ),
                              if (updatedMatch.statut == 'MI_TEMPS')
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Lancer 2ème Mi-Temps'),
                                    onPressed: () => matchProv.superAdminUpdateMatchStatus(auth, updatedMatch.id, 'DEUXIEME_MI_TEMPS'),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              // Si score nul → bouton "Tir au But", sinon "Terminer"
                              SizedBox(
                                width: double.infinity,
                                child: (updatedMatch.scoreAsc == updatedMatch.scoreAdv)
                                  ? ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1A237E),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.sports_score, size: 20),
                                      label: const Text('🎯 Tir au But', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      onPressed: () async {
                                        try {
                                          await matchProv.superAdminUpdateMatchStatus(auth, updatedMatch.id, 'TIR_AU_BUT');
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
                                          }
                                        }
                                      },
                                    )
                                  : ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0A5C36),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.stop, size: 20),
                                      label: const Text('🏁 Fin du Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('🏁 Terminer le match ?'),
                                            content: Text('Score final : ${updatedMatch.teamAName} ${updatedMatch.scoreAsc ?? 0} - ${updatedMatch.scoreAdv ?? 0} ${updatedMatch.teamBName}'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Confirmer'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await matchProv.superAdminUpdateMatchStatus(auth, updatedMatch.id, 'TERMINE');
                                          if (context.mounted) Navigator.pop(context);
                                        }
                                      },
                                    ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
