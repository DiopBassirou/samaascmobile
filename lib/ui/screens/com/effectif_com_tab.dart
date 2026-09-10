import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/match_provider.dart';
import '../../../providers/convocation_provider.dart';
import '../../widgets/player_card.dart';
import '../../widgets/tactical_pitch_widget.dart';
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

  void _showAddPlayerDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedPoste = 'Milieu Central (8)';
    bool isSaving = false;
    final positions = groupedPositions;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.person_add, color: Color(0xFF0A5C36)),
                SizedBox(width: 8),
                Text('Ajouter un Joueur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom & Prénom',
                        hintText: 'ex: Moussa Ndiaye',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Poste du joueur :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    // Positions groupées par catégorie
                    ...positions.entries.map((entry) {
                      final category = entry.key;
                      final categoryPositions = entry.value;
                      Color catColor;
                      switch (category) {
                        case 'Gardien': catColor = const Color(0xFFFF9800); break;
                        case 'Défenseur': catColor = const Color(0xFF2196F3); break;
                        case 'Milieu': catColor = const Color(0xFF4CAF50); break;
                        case 'Attaquant': catColor = const Color(0xFFE53935); break;
                        default: catColor = Colors.grey;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: catColor)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: categoryPositions.map((tp) {
                              final selected = selectedPoste == tp.label;
                              return ChoiceChip(
                                label: Text(tp.label, style: TextStyle(fontSize: 11.5)),
                                selected: selected,
                                selectedColor: catColor,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : Colors.black87,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) setDialogState(() => selectedPoste = tp.label);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5C36),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez saisir le nom du joueur')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          final authProv = Provider.of<AuthProvider>(context, listen: false);
                          final playerProv = Provider.of<PlayerProvider>(context, listen: false);
                          await playerProv.addPlayer(authProv, name, selectedPoste);

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Joueur "$name" ($selectedPoste) ajouté !'),
                                backgroundColor: const Color(0xFF0A5C36),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur lors de l\'ajout : $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sélectionnez les Convoqués', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text('${convoques.length} joueurs sélectionnés', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A5C36),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Ajouter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddPlayerDialog(context),
                  ),
                ],
              ),
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
              const Text('Aperçu Tactique du 11 de départ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${titulaires.length} titulaires sur le terrain', style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              
              // BeSoccer Style Tactical Pitch Widget!
              TacticalPitchWidget(titulaires: titulaires),

              const SizedBox(height: 20),
              const Text('Liste des Titulaires', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

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
                  if (!context.mounted) return;
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
