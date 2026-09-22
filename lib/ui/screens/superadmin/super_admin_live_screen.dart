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
                    description: isAsc ? 'But de ${playerName ?? "l\'équipe"} ($minute\')' : 'But adverse ($minute\')',
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
                          Text('${updatedMatch.scoreAsc ?? 0} - ${updatedMatch.scoreAdv ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
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
                                await matchProv.updateMatchStatus(auth, updatedMatch.id, 'EN_COURS');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                              }
                            },
                          ),
                        )
                      else if (updatedMatch.statut == 'EN_COURS' || updatedMatch.statut == 'MI_TEMPS' || updatedMatch.statut == 'DEUXIEME_MI_TEMPS')
                        Column(
                          children: [
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
                                  onPressed: () => matchProv.updateMatchStatus(auth, updatedMatch.id, 'MI_TEMPS'),
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
                                  onPressed: () => matchProv.updateMatchStatus(auth, updatedMatch.id, 'DEUXIEME_MI_TEMPS'),
                                ),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A5C36),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.stop),
                                label: const Text('Fin du Match'),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Terminer le match ?'),
                                      content: const Text('Le score sera définitif et le classement mis à jour.'),
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
                                    await matchProv.updateMatchStatus(auth, updatedMatch.id, 'TERMINE');
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                },
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
        },
      ),
    );
  }
}
