import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../models/player_model.dart';
import '../../widgets/player_card.dart';
import '../../../providers/auth_provider.dart';

class EffectifTab extends StatefulWidget {
  const EffectifTab({super.key});

  @override
  State<EffectifTab> createState() => _EffectifTabState();
}

class _EffectifTabState extends State<EffectifTab> {
  int _selectedTab = 0; // 0=Tous, 1=11 de départ, 2=Remplaçants, 3=Non retenus

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final playerProv = Provider.of<PlayerProvider>(context, listen: false);
      if (playerProv.players.isEmpty) {
        playerProv.fetchPlayers(auth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)));
        
        final titulaires = provider.titulaires;
        final remplacants = provider.remplacants;
        final nonRetenus = provider.nonRetenus;
        
        List<Player> playersToDisplay;
        switch (_selectedTab) {
          case 1: playersToDisplay = List.from(titulaires); break;
          case 2: playersToDisplay = List.from(remplacants); break;
          case 3: playersToDisplay = List.from(nonRetenus); break;
          default: playersToDisplay = List.from(provider.players);
        }

        // Sort players by position
        playersToDisplay.sort((a, b) {
          final order = {'Gardien': 1, 'Défenseur': 2, 'Milieu': 3, 'Attaquant': 4};
          final posA = order[a.poste] ?? 99;
          final posB = order[b.poste] ?? 99;
          return posA.compareTo(posB);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with count
              Row(
                children: [
                  const Text('Effectif', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A5C36).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${provider.players.length} joueurs', style: const TextStyle(color: Color(0xFF0A5C36), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats cards
              Row(
                children: [
                  _buildStatCard('11', 'Titulaires', const Color(0xFF2E7D32), titulaires.length),
                  const SizedBox(width: 8),
                  _buildStatCard('🔄', 'Remplaçants', const Color(0xFF00897B), remplacants.length),
                  const SizedBox(width: 8),
                  _buildStatCard('—', 'Non retenus', Colors.grey, nonRetenus.length),
                ],
              ),
              const SizedBox(height: 16),

              // Tab selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabChip('Tous (${provider.players.length})', 0),
                    const SizedBox(width: 8),
                    _buildTabChip('XI de Départ (${titulaires.length})', 1),
                    const SizedBox(width: 8),
                    _buildTabChip('Remplaçants (${remplacants.length})', 2),
                    const SizedBox(width: 8),
                    _buildTabChip('Non retenus (${nonRetenus.length})', 3),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Section label removed as per user request

              if (playersToDisplay.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Icon(Icons.person_off, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text('Aucun joueur dans cette catégorie', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                      ],
                    ),
                  ),
                )
              else
                ...playersToDisplay.map((p) {
                  String statusLabel;
                  if (p.statutConvocation == 'TITULAIRE') {
                    statusLabel = 'Titulaire';
                  } else if (p.statutConvocation == 'REMPLACANT') {
                    statusLabel = 'Remplaçant';
                  } else {
                    statusLabel = 'Non retenu';
                  }
                  return PlayerCard(
                    name: p.nom,
                    position: p.poste,
                    status: statusLabel,
                  );
                }),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatCard(String emoji, String label, Color color, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0A5C36) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: selected ? const Color(0xFF0A5C36) : Colors.grey[300]!),
          boxShadow: selected ? [BoxShadow(color: const Color(0xFF0A5C36).withValues(alpha: 0.2), blurRadius: 6)] : null,
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : Colors.grey[700],
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        )),
      ),
    );
  }
}
