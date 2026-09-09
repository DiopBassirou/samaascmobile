import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/classement_provider.dart';
import '../../../providers/match_provider.dart';

class ClassementTab extends StatelessWidget {
  const ClassementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ClassementProvider, MatchProvider>(
      builder: (context, provider, matchProvider, child) {
        if (provider.isLoading || matchProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)));
        }

        final teams = provider.teams.isNotEmpty ? provider.teams : [
          {'rank': 1, 'name': 'Notre ASC', 'j': 0, 'v': 0, 'n': 0, 'd': 0, 'db': '0', 'pts': 0, 'highlight': true},
        ];

        final finishedMatches = matchProvider.matches.where((m) => m.statut == 'TERMINE').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Classement - Poule A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                          const Expanded(child: Text('ÉQUIPE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
                          ...['J', 'V', 'N', 'D', 'DB', 'PTS'].map((h) => SizedBox(
                            width: 30,
                            child: Text(h, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                          )),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...teams.map((t) => Container(
                      color: t['highlight'] == true ? const Color(0xFFE8F5E9) : null,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: t['highlight'] == true ? const Color(0xFF4CAF50) : Colors.grey[200],
                              ),
                              child: Center(child: Text('${t['rank'] ?? 0}', style: TextStyle(
                                color: t['highlight'] == true ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold, fontSize: 12,
                              ))),
                            ),
                          ),
                          Expanded(child: Text('${t['name'] ?? ''}', style: TextStyle(fontWeight: t['highlight'] == true ? FontWeight.bold : FontWeight.normal))),
                          ...['j', 'v', 'n', 'd', 'db', 'pts'].map((key) => SizedBox(
                            width: 30,
                            child: Text(
                              '${t[key] ?? 0}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: key == 'pts' ? FontWeight.bold : FontWeight.normal,
                                color: key == 'pts' ? const Color(0xFF1B5E20) : null,
                              ),
                            ),
                          )),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text('Derniers Résultats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                ),
                child: finishedMatches.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('Aucun match terminé pour le moment', style: TextStyle(color: Colors.grey))),
                      )
                    : Column(
                        children: finishedMatches.map((m) {
                          return Column(
                            children: [
                              _buildResult('Notre ASC', '${m.scoreAsc ?? 0} - ${m.scoreAdv ?? 0}', m.opponentName),
                              if (m != finishedMatches.last) const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildResult(String home, String score, String away) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(home, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(score, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 16)),
          Expanded(child: Text(away, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
