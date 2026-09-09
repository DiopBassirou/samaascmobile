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
    switch (position.toLowerCase()) {
      case 'gardien': return const Color(0xFFFF8F00);
      case 'defenseur': case 'défenseur': return const Color(0xFF1565C0);
      case 'milieu': return const Color(0xFF2E7D32);
      case 'attaquant': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }

  IconData get _positionIcon {
    switch (position.toLowerCase()) {
      case 'gardien': return Icons.sports_handball;
      case 'defenseur': case 'défenseur': return Icons.shield;
      case 'milieu': return Icons.gps_fixed;
      case 'attaquant': return Icons.flash_on;
      default: return Icons.person;
    }
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
