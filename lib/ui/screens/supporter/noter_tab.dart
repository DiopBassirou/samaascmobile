import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sama_asc_mobile/ui/screens/supporter/player_rating_screen.dart';
import 'package:sama_asc_mobile/providers/match_provider.dart';

class NoterTab extends StatelessWidget {
  const NoterTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, matchProv, child) {
        final lastMatch = matchProv.matches.isNotEmpty ? matchProv.matches.first : null;
        final matchId = lastMatch?.id ?? 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F8A4B).withValues(alpha: 0.2), // Remplacé amber par vert
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFF0F8A4B), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note des Joueurs',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A5C36),
                          ),
                        ),
                        Text(
                          'Donnez une note de 1 à 5 pour chaque joueur',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Match Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0A5C36),
                      Color(0xFF0F8A4B),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      lastMatch != null ? 'MATCH CONCERNÉ' : 'DERNIER MATCH',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lastMatch != null
                          ? 'Notre ASC vs ${lastMatch.opponentName}'
                          : 'Notre ASC vs Adversaire',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lastMatch != null
                            ? 'Score : ${lastMatch.scoreAsc ?? 0} - ${lastMatch.scoreAdv ?? 0}'
                            : 'Score : 2 - 1',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerRatingScreen(matchId: matchId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F8A4B), // Remplacé amber
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
                      label: const Text(
                        'NOTER CE MATCH',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Information card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF0F8A4B)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vos votes sont 100% anonymes et permettent de désigner l\'Homme du Match.',
                        style: TextStyle(color: Color(0xFF1B5E20), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}