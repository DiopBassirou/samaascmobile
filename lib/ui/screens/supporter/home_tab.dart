import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/match_provider.dart';
import '../../../providers/news_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/match_model.dart';
import '../../../ui/widgets/match_timer.dart';
import '../../widgets/team_logo.dart';

import '../../../services/device_service.dart';

class SupporterHomeTab extends StatefulWidget {
  const SupporterHomeTab({super.key});

  @override
  State<SupporterHomeTab> createState() => _SupporterHomeTabState();
}

class _SupporterHomeTabState extends State<SupporterHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final matchProv = Provider.of<MatchProvider>(context, listen: false);
      final newsProv = Provider.of<NewsProvider>(context, listen: false);
      final favAsc = await DeviceService().getFavoriteAsc();
      final favAscCode = favAsc?['code_unique'];
      if (matchProv.matches.isEmpty) matchProv.fetchMatches(auth, favAscCode);
      if (newsProv.news.isEmpty) newsProv.fetchNews(auth, favAscCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MatchProvider, NewsProvider>(
      builder: (context, matchProvider, newsProvider, child) {
        final currentMatches = matchProvider.matches.where((m) => m.statut == 'EN_COURS' || m.statut == 'MI_TEMPS').toList();
        final nextMatches = matchProvider.matches.where((m) => m.statut == 'A_VENIR').toList();
        final lastMatches = matchProvider.matches.where((m) => m.statut == 'TERMINE').toList();
        lastMatches.sort((a, b) => b.dateMatch.compareTo(a.dateMatch)); // desc
        nextMatches.sort((a, b) => a.dateMatch.compareTo(b.dateMatch)); // asc
        
        final lastMatch = lastMatches.isNotEmpty ? lastMatches.first : null;

        List<MatchGame> matchesToDisplay = [];
        if (currentMatches.isNotEmpty) {
          matchesToDisplay = currentMatches;
        } else if (nextMatches.isNotEmpty) {
          matchesToDisplay = nextMatches;
        } else if (lastMatches.isNotEmpty) {
          matchesToDisplay = lastMatches.take(2).toList();
        }

        final news = newsProvider.news.isNotEmpty ? newsProvider.news.first : null;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        return RefreshIndicator(
          onRefresh: () async {
            final favAsc = await DeviceService().getFavoriteAsc();
            final favAscCode = favAsc?['code_unique'];
            await matchProvider.fetchMatches(authProvider, favAscCode);
            if (context.mounted) {
              await newsProvider.fetchNews(authProvider, favAscCode);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Notification du dimanche
              if (DateTime.now().weekday == DateTime.sunday) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
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
                const SizedBox(height: 20),
              ],

              // === Cartes de Matchs ===
              if (matchesToDisplay.isEmpty) ...[
                // Pas de matchs
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.sports_soccer, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text('Aucun match programmé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Les prochains matchs apparaîtront ici.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (matchesToDisplay.isNotEmpty) ...[
                ...matchesToDisplay.map((match) => _buildMatchCard(match, authProvider)),
              ],

              // Fil du Match (Timeline d'événements - affiché uniquement pour le premier match en cours si existant)
              if (matchesToDisplay.isNotEmpty &&
                  (matchesToDisplay.first.statut == 'EN_COURS' ||
                      matchesToDisplay.first.statut == 'MI_TEMPS')) ...[
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
                          Text('${matchesToDisplay.first.events.length} événement(s)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildEventsTimeline(matchesToDisplay.first.events),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Homme du match
              if (lastMatch != null && lastMatch.hommeDuMatch != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A5C36),
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
                const SizedBox(height: 20),
              ],

              // Actualités
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
        ));
      },
    );
  }

  Widget _buildMatchCard(MatchGame match, AuthProvider authProvider) {
    final isLive = match.statut == 'EN_COURS' || match.statut == 'MI_TEMPS';
    final isNext = match.statut == 'A_VENIR';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.isToday ? "Match d'Aujourd'hui" 
            : match.isYesterday ? "Match d'Hier" 
            : match.isTomorrow ? "Match de Demain" 
            : "Match du ${_formatDate(match.dateMatch)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0A5C36)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLive
                    ? [const Color(0xFF7B0000), const Color(0xFF1B0000)]
                    : [const Color(0xFF0A5C36), const Color(0xFF0F8A4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                // Ligne de badges : Statut + Catégorie
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge Statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isLive ? Colors.red : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            const Icon(Icons.circle, color: Colors.white, size: 8),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isLive
                                ? (match.statut == 'MI_TEMPS' ? '⏸ MI-TEMPS' : '🔴 EN DIRECT')
                                : (isNext ? '🗓 PROCHAIN MATCH' : '✅ DERNIER MATCH'),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge Catégorie (CADET / SENIOR)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: match.categorie == 'CADET'
                            ? const Color(0xFF0F8A4B)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        match.categorie == 'CADET' ? '🏃 Cadets' : '🧑 Seniors',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeam(match.teamAName, Colors.greenAccent, logoUrl: match.teamALogo),
                    if (isNext)
                      const Text('VS', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))
                    else
                      Text(
                        '${match.scoreAsc ?? 0} - ${match.scoreAdv ?? 0}',
                        style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
                      ),
                    _buildTeam(match.teamBName, Colors.green, logoUrl: match.teamBLogo),
                  ],
                ),
                const SizedBox(height: 12),

                // Chronomètre (seulement EN_COURS ou MI_TEMPS)
                if (isLive)
                  MatchTimer(match: match),

                const SizedBox(height: 12),

                // Chips d'info : Poule | Phase | Terrain | Date relative
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (match.pouleName != null)
                      _buildInfoChip(Icons.emoji_events_outlined, match.pouleName!),
                    if (match.phase != null && match.phase != match.pouleName)
                      _buildInfoChip(Icons.workspaces_outline, match.phase!),
                    if (match.lieu != null && match.lieu!.isNotEmpty)
                      _buildInfoChip(Icons.location_on_outlined, match.lieu!),
                    _buildInfoChip(
                      Icons.calendar_today_outlined,
                      match.isToday
                          ? "Aujourd'hui à ${_formatTime(match.dateMatch)}"
                          : match.isYesterday
                              ? "Hier"
                              : match.isTomorrow
                                  ? "Demain à ${_formatTime(match.dateMatch)}"
                                  : "${_formatDate(match.dateMatch)} à ${_formatTime(match.dateMatch)}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
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
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text("${e.minute}'", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Widget _buildTeam(String name, Color color, {String? logoUrl}) {
    return Column(
      children: [
        TeamLogo(
          teamName: name,
          logoUrl: logoUrl,
          fallbackColor: color,
          size: 52,
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 110,
          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  static Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  static String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _formatTime(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }
}
