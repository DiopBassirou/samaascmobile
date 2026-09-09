import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/match_provider.dart';
import '../../../providers/news_provider.dart';

import '../../../providers/auth_provider.dart';

class SupporterHomeTab extends StatefulWidget {
  const SupporterHomeTab({super.key});

  @override
  State<SupporterHomeTab> createState() => _SupporterHomeTabState();
}

class _SupporterHomeTabState extends State<SupporterHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final matchProv = Provider.of<MatchProvider>(context, listen: false);
      final newsProv = Provider.of<NewsProvider>(context, listen: false);
      if (matchProv.matches.isEmpty) matchProv.fetchMatches(auth);
      if (newsProv.news.isEmpty) newsProv.fetchNews(auth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MatchProvider, NewsProvider>(
      builder: (context, matchProvider, newsProvider, child) {
        final currentMatch = matchProvider.currentMatch;
        final nextMatch = matchProvider.nextMatch;
        final lastMatch = matchProvider.lastMatch;
        final matchToDisplay = currentMatch ?? nextMatch ?? lastMatch;
        final isLive = currentMatch != null;
        final isNext = currentMatch == null && nextMatch != null;
        final news = newsProvider.news.isNotEmpty ? newsProvider.news.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification banner (Seulement le dimanche)
              if (DateTime.now().weekday == DateTime.sunday)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // Vert très clair
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Color(0xFF0F8A4B), size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("C'est dimanche !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              "N'oublie pas ta cotisation de 200F pour soutenir l'ASC.",
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (DateTime.now().weekday == DateTime.sunday)
                const SizedBox(height: 20),

              // Live Score Card
              if (matchToDisplay != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A5C36), Color(0xFF0F8A4B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive ? Colors.red : (isNext ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLive) const Icon(Icons.circle, color: Colors.white, size: 8),
                            if (isLive) const SizedBox(width: 5),
                            Text(
                              isLive ? (matchToDisplay.statut == 'MI_TEMPS' ? '⏸ MI-TEMPS' : '🔴 EN DIRECT') : (isNext ? 'PROCHAIN MATCH' : 'DERNIER MATCH'), 
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTeam('Notre ASC', Colors.greenAccent),
                          if (isNext)
                            const Text('VS', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))
                          else
                            Text('${matchToDisplay.scoreAsc ?? 0} - ${matchToDisplay.scoreAdv ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                          _buildTeam(matchToDisplay.opponentName, Colors.blue),
                        ],
                      ),
                      if (isLive) ...[
                        const SizedBox(height: 8),
                        Text(matchToDisplay.statut == 'MI_TEMPS' ? "Mi-Temps" : "Match en cours", style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              if (matchToDisplay != null)
                const SizedBox(height: 20),

              // Fil d'actualité du match (Timeline)
              if (matchToDisplay != null && (matchToDisplay.statut == 'EN_COURS' || matchToDisplay.statut == 'MI_TEMPS' || matchToDisplay.statut == 'TERMINE')) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
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
                          Text('${matchToDisplay.events.length} événement(s)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildEventsTimeline(matchToDisplay.events),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Homme du match (S'il existe pour le dernier match)
              if (lastMatch != null && lastMatch.hommeDuMatch != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A5C36), // Changé du jaune au vert
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 36),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HOMME DU DERNIER MATCH', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          Text(lastMatch.hommeDuMatch!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              if (lastMatch != null && lastMatch.hommeDuMatch != null)
                const SizedBox(height: 20),

              // Actualites
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Actualités', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Voir tout', style: TextStyle(color: Color(0xFF1B5E20))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (news != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA5D6A7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Icon(Icons.campaign, size: 50, color: Colors.white)),
                      ),
                      const SizedBox(height: 10),
                      Text(news.type, style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(news.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(news.message, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildEventsTimeline(List<dynamic> events) {
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

  static Widget _buildTeam(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: Center(child: Icon(Icons.circle, color: color, size: 18)),
        ),
        const SizedBox(height: 5),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
