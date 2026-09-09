import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/match_provider.dart';
import '../../../providers/convocation_provider.dart';
import '../../widgets/player_card.dart';
import '../../../models/player_model.dart';

class EffectifComTab extends StatefulWidget {
  const EffectifComTab({super.key});
  @override
  State<EffectifComTab> createState() => _EffectifComTabState();
}

class _EffectifComTabState extends State<EffectifComTab> {
  final Map<int, String> _selections = {};
  int _activeTab = 0; // 0 = Tous les joueurs, 1 = Convoqués, 2 = 11 de départ
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.players.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Player> players = provider.players.cast<Player>().toList();
        
        // Initialize state if empty
        if (_selections.isEmpty && players.isNotEmpty) {
          for (var p in players) {
            _selections[p.id] = p.statutConvocation ?? 'REPOS';
          }
        }

        // Toujours ordonner par poste: Gardien -> Défenseur -> Milieu -> Attaquant
        players.sort((a, b) {
          final order = {'Gardien': 1, 'Défenseur': 2, 'Milieu': 3, 'Attaquant': 4};
          final posA = order[a.poste] ?? 99;
          final posB = order[b.poste] ?? 99;
          return posA.compareTo(posB);
        });

        final convoques = players.where((p) => (_selections[p.id] ?? 'REPOS') != 'REPOS').toList();
        final titulaires = players.where((p) => (_selections[p.id] ?? 'REPOS') == 'TITULAIRE').toList();

        return Column(children: [
          // Header Tabs
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildTopTab(0, 'Tous les\njoueurs', Icons.groups)),
                const SizedBox(width: 6),
                Expanded(child: _buildTopTab(1, 'Convoqués', Icons.checklist)),
                const SizedBox(width: 6),
                Expanded(child: _buildTopTab(2, '11 de\ndépart', Icons.stars)),
              ],
            ),
          ),
          
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_activeTab == 0) ...[
              const Text('Sélectionnez les Convoqués', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${convoques.length} joueurs sélectionnés', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              ...players.map((p) {
                final isConvoque = (_selections[p.id] ?? 'REPOS') != 'REPOS';
                return PlayerCard(
                  name: p.nom, position: p.poste,
                  trailing: Checkbox(
                    value: isConvoque,
                    activeColor: const Color(0xFF0A5C36),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selections[p.id] = 'REMPLACANT'; // Par défaut quand on convoque
                        } else {
                          _selections[p.id] = 'REPOS';
                        }
                      });
                    },
                  ),
                );
              }),
            ] else if (_activeTab == 1) ...[
              const Text('Sélectionnez le 11 de départ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${titulaires.length} titulaires sélectionnés', style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              
              if (convoques.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Aucun joueur convoqué.")))
              else
                ...convoques.map((p) {
                  bool isTitulaire = _selections[p.id] == 'TITULAIRE';
                  return PlayerCard(
                    name: p.nom, position: p.poste,
                    trailing: Checkbox(
                      value: isTitulaire,
                      activeColor: Colors.amber[700],
                      checkColor: Colors.white,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selections[p.id] = 'TITULAIRE';
                          } else {
                            _selections[p.id] = 'REMPLACANT';
                          }
                        });
                      },
                    ),
                  );
                }),
            ] else ...[
              const Text('Aperçu du 11 de départ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${titulaires.length} titulaires', style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              
              if (titulaires.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Aucun titulaire sélectionné.")))
              else
                ...titulaires.map((p) {
                  return PlayerCard(
                    name: p.nom, position: p.poste,
                    trailing: const Icon(Icons.stars, color: Colors.amber),
                  );
                }),
            ]
          ]))),
          
          // Publish Button
          Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20), 
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            icon: _isSubmitting 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('📝', style: TextStyle(fontSize: 18)),
            label: Text(_activeTab == 0 ? 'Publier la Convocation' : 'Publier le 11 de départ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: _isSubmitting ? null : () async {
              final matchProv = Provider.of<MatchProvider>(context, listen: false);
              final convoProv = Provider.of<ConvocationProvider>(context, listen: false);
              final targetMatch = matchProv.currentMatch ?? matchProv.nextMatch ?? matchProv.lastMatch;
              
              if (targetMatch == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun match disponible'), backgroundColor: Colors.red));
                return;
              }

              for (var p in players) {
                convoProv.updateSelection(p.id, _selections[p.id] ?? 'REPOS');
              }

              setState(() => _isSubmitting = true);
              try {
                await convoProv.submit(targetMatch.id);
                if (context.mounted) {
                  final authProv = Provider.of<AuthProvider>(context, listen: false);
                  await Provider.of<PlayerProvider>(context, listen: false).fetchPlayers(authProv);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Effectif publié avec succès !', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                  
                  // Auto-switch to next tab
                  setState(() {
                    if (_activeTab < 2) {
                      _activeTab++;
                    }
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur réseau. Veuillez réessayer. Détails: $e'), backgroundColor: Colors.red));
                }
              } finally {
                if (mounted) setState(() => _isSubmitting = false);
              }
            },
          ))),
        ]);
      }
    );
  }

  Widget _buildTopTab(int index, String label, IconData icon) {
    bool active = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0A5C36) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF0A5C36) : Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : Colors.grey[800], fontWeight: active ? FontWeight.bold : FontWeight.w600, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

//  