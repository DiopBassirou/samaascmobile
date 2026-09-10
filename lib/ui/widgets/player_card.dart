import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final String position;
  final int? number;
  final String? status;
  final Widget? trailing;
  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.name,
    required this.position,
    this.number,
    this.status,
    this.trailing,
    this.onTap,
  });

  Color get _positionColor {
    final lower = position.toLowerCase();
    if (lower.contains('gardien') || lower == 'gk') return const Color(0xFFFF8F00);
    if (lower.contains('défenseur') || lower.contains('defenseur') || lower.contains('latéral') || lower.contains('lateral') || lower.contains('libéro') || lower.contains('libero') || lower == 'dc' || lower == 'cb' || lower == 'lb' || lower == 'rb') return const Color(0xFF1976D2);
    if (lower.contains('milieu') || lower.contains('le 6') || lower.contains('le 10') || lower == 'mc' || lower == 'cdm' || lower == 'cam') return const Color(0xFF2E7D32);
    if (lower.contains('attaquant') || lower.contains('ailier') || lower.contains('avant-centre') || lower.contains('pointe') || lower == 'st' || lower == 'lw' || lower == 'rw') return const Color(0xFFC62828);
    return Colors.grey;
  }

  IconData get _positionIcon {
    final lower = position.toLowerCase();
    if (lower.contains('gardien') || lower == 'gk') return Icons.sports_handball;
    if (lower.contains('défenseur') || lower.contains('defenseur') || lower.contains('libéro') || lower.contains('libero') || lower == 'dc' || lower == 'cb') return Icons.shield;
    if (lower.contains('latéral') || lower.contains('lateral') || lower == 'lb' || lower == 'rb') return Icons.shield;
    if (lower.contains('milieu défensif') || lower.contains('le 6') || lower == 'cdm') return Icons.compare_arrows;
    if (lower.contains('milieu offensif') || lower.contains('le 10') || lower == 'cam') return Icons.auto_awesome;
    if (lower.contains('milieu') || lower == 'mc' || lower == 'cm') return Icons.gps_fixed;
    if (lower.contains('ailier') || lower == 'lw' || lower == 'rw') return Icons.bolt;
    if (lower.contains('attaquant') || lower.contains('avant-centre') || lower.contains('pointe') || lower == 'st') return Icons.flash_on;
    return Icons.person;
  }

  Color get _statusColor {
    if (status == null) return Colors.grey;
    switch (status!.toLowerCase()) {
      case 'titulaire': return const Color(0xFF2E7D32);
      case 'remplaçant': case 'remplacant': return const Color(0xFF00897B);
      case 'non retenu': return Colors.grey[500]!;
      default: return Colors.grey;
    }
  }

  IconData get _statusIcon {
    if (status == null) return Icons.remove;
    switch (status!.toLowerCase()) {
      case 'titulaire': return Icons.stars;
      case 'remplaçant': case 'remplacant': return Icons.swap_horiz;
      case 'non retenu': return Icons.remove_circle_outline;
      default: return Icons.remove;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Position badge with number
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_positionColor, _positionColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_positionIcon, color: Colors.white, size: 18),
                    if (number != null)
                      Text('$number', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 2),
                    Text(
                      position.toUpperCase(),
                      style: TextStyle(color: _positionColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!
              else if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 14, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status!,
                        style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
