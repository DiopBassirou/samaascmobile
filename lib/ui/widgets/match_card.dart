import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import 'match_timer.dart';

class MatchCard extends StatelessWidget {
  final MatchGame match;
  final bool isLive;
  final bool isNext;

  const MatchCard({
    super.key,
    required this.match,
    required this.isLive,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 6)),
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
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
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score ou VS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeam('Notre ASC', Colors.greenAccent),
              if (isNext)
                const Text('VS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold))
              else
                Text(
                  '${match.scoreAsc ?? 0} - ${match.scoreAdv ?? 0}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold),
                ),
              _buildTeam(match.opponentName, Colors.green),
            ],
          ),
          const SizedBox(height: 12),

          // Chronomètre (seulement EN_COURS ou MI_TEMPS)
          if (isLive) MatchTimer(match: match),

          const SizedBox(height: 12),

          // Chips d'info : Poule | Phase | Terrain | Date relative
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (match.pouleName != null)
                _buildInfoChip(Icons.emoji_events_outlined, match.pouleName!),
              if (match.phase != null)
                _buildInfoChip(Icons.workspaces_outline, match.phase!),
              if (match.lieu != null && match.lieu!.isNotEmpty)
                _buildInfoChip(Icons.location_on_outlined, match.lieu!),
              _buildInfoChip(
                Icons.calendar_today_outlined,
                match.isToday
                    ? "Aujourd'hui"
                    : match.isYesterday
                        ? 'Hier'
                        : match.isTomorrow
                            ? 'Demain'
                            : _formatDate(match.dateMatch),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeam(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: Center(child: Icon(Icons.circle, color: color, size: 18)),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 80,
          child: Text(name,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
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
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
