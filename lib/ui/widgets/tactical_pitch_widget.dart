import 'package:flutter/material.dart';
import '../../models/player_model.dart';

/// Positions détaillées avec leurs coordonnées sur le terrain
/// Le terrain va de haut (attaque) vers bas (gardien)
/// x: 0.0 = gauche, 1.0 = droite
/// y: 0.0 = haut (attaque), 1.0 = bas (gardien)
class TacticalPosition {
  final String code;
  final String label;
  final String shortLabel;
  final String category; // Gardien, Défenseur, Milieu, Attaquant
  final double x;
  final double y;
  final Color color;
  final IconData icon;

  const TacticalPosition({
    required this.code,
    required this.label,
    required this.shortLabel,
    required this.category,
    required this.x,
    required this.y,
    required this.color,
    required this.icon,
  });
}

const List<TacticalPosition> allTacticalPositions = [
  // ─── GARDIEN ───
  TacticalPosition(code: 'GK', label: 'Gardien', shortLabel: 'GK', category: 'Gardien', x: 0.5, y: 0.92, color: Color(0xFFFF9800), icon: Icons.sports_handball),

  // ─── DÉFENSEURS ───
  TacticalPosition(code: 'LB', label: 'Latéral Gauche', shortLabel: 'LG', category: 'Défenseur', x: 0.12, y: 0.76, color: Color(0xFF2196F3), icon: Icons.shield),
  TacticalPosition(code: 'CB', label: 'Défenseur Central', shortLabel: 'DC', category: 'Défenseur', x: 0.37, y: 0.80, color: Color(0xFF2196F3), icon: Icons.shield),
  TacticalPosition(code: 'SW', label: 'Libéro', shortLabel: 'LIB', category: 'Défenseur', x: 0.5, y: 0.84, color: Color(0xFF1565C0), icon: Icons.security),
  TacticalPosition(code: 'CB2', label: 'Défenseur Central', shortLabel: 'DC', category: 'Défenseur', x: 0.63, y: 0.80, color: Color(0xFF2196F3), icon: Icons.shield),
  TacticalPosition(code: 'RB', label: 'Latéral Droit', shortLabel: 'LD', category: 'Défenseur', x: 0.88, y: 0.76, color: Color(0xFF2196F3), icon: Icons.shield),

  // ─── MILIEUX ───
  TacticalPosition(code: 'CDM', label: 'Milieu Défensif (6)', shortLabel: '6', category: 'Milieu', x: 0.5, y: 0.62, color: Color(0xFF4CAF50), icon: Icons.compare_arrows),
  TacticalPosition(code: 'LM', label: 'Milieu Gauche', shortLabel: 'MG', category: 'Milieu', x: 0.15, y: 0.52, color: Color(0xFF4CAF50), icon: Icons.compare_arrows),
  TacticalPosition(code: 'CM', label: 'Milieu Central (8)', shortLabel: '8', category: 'Milieu', x: 0.38, y: 0.52, color: Color(0xFF4CAF50), icon: Icons.compare_arrows),
  TacticalPosition(code: 'CM2', label: 'Milieu Central', shortLabel: 'MC', category: 'Milieu', x: 0.62, y: 0.52, color: Color(0xFF4CAF50), icon: Icons.compare_arrows),
  TacticalPosition(code: 'RM', label: 'Milieu Droit', shortLabel: 'MD', category: 'Milieu', x: 0.85, y: 0.52, color: Color(0xFF4CAF50), icon: Icons.compare_arrows),
  TacticalPosition(code: 'CAM', label: 'Milieu Offensif (10)', shortLabel: '10', category: 'Milieu', x: 0.5, y: 0.40, color: Color(0xFF66BB6A), icon: Icons.auto_awesome),

  // ─── ATTAQUANTS ───
  TacticalPosition(code: 'LW', label: 'Ailier Gauche', shortLabel: 'AG', category: 'Attaquant', x: 0.15, y: 0.25, color: Color(0xFFE53935), icon: Icons.bolt),
  TacticalPosition(code: 'ST', label: 'Avant-Centre (Pointe)', shortLabel: 'AC', category: 'Attaquant', x: 0.5, y: 0.18, color: Color(0xFFE53935), icon: Icons.bolt),
  TacticalPosition(code: 'SS', label: 'Second Attaquant', shortLabel: '2ndAT', category: 'Attaquant', x: 0.5, y: 0.30, color: Color(0xFFEF5350), icon: Icons.bolt),
  TacticalPosition(code: 'RW', label: 'Ailier Droit', shortLabel: 'AD', category: 'Attaquant', x: 0.85, y: 0.25, color: Color(0xFFE53935), icon: Icons.bolt),
];

/// Retourne la TacticalPosition correspondant au poste d'un joueur
TacticalPosition? findTacticalPosition(String poste) {
  final lower = poste.toLowerCase().trim();

  // Recherche exacte par code
  for (var tp in allTacticalPositions) {
    if (tp.code.toLowerCase() == lower || tp.label.toLowerCase() == lower) return tp;
  }

  // Recherche par mots-clés
  if (lower.contains('gardien') || lower == 'gk' || lower == 'goal') {
    return allTacticalPositions.firstWhere((p) => p.code == 'GK');
  }
  if (lower.contains('latéral gauche') || lower.contains('lateral gauche') || lower == 'lg' || lower == 'lb') {
    return allTacticalPositions.firstWhere((p) => p.code == 'LB');
  }
  if (lower.contains('latéral droit') || lower.contains('lateral droit') || lower == 'ld' || lower == 'rb') {
    return allTacticalPositions.firstWhere((p) => p.code == 'RB');
  }
  if (lower.contains('libéro') || lower.contains('libero') || lower == 'sw') {
    return allTacticalPositions.firstWhere((p) => p.code == 'SW');
  }
  if (lower.contains('défenseur') || lower.contains('defenseur') || lower == 'dc' || lower == 'cb') {
    return allTacticalPositions.firstWhere((p) => p.code == 'CB');
  }
  if (lower.contains('milieu défensif') || lower.contains('milieu defensif') || lower.contains('le 6') || lower == '6' || lower == 'cdm') {
    return allTacticalPositions.firstWhere((p) => p.code == 'CDM');
  }
  if (lower.contains('milieu offensif') || lower.contains('le 10') || lower == '10' || lower == 'cam' || lower.contains('meneur')) {
    return allTacticalPositions.firstWhere((p) => p.code == 'CAM');
  }
  if (lower.contains('milieu gauche') || lower == 'mg' || lower == 'lm') {
    return allTacticalPositions.firstWhere((p) => p.code == 'LM');
  }
  if (lower.contains('milieu droit') || lower == 'md' || lower == 'rm') {
    return allTacticalPositions.firstWhere((p) => p.code == 'RM');
  }
  if (lower.contains('milieu central') || lower.contains('milieu') || lower == 'mc' || lower == 'cm') {
    return allTacticalPositions.firstWhere((p) => p.code == 'CM');
  }
  if (lower.contains('ailier gauche') || lower == 'ag' || lower == 'lw') {
    return allTacticalPositions.firstWhere((p) => p.code == 'LW');
  }
  if (lower.contains('ailier droit') || lower == 'ad' || lower == 'rw') {
    return allTacticalPositions.firstWhere((p) => p.code == 'RW');
  }
  if (lower.contains('pointe') || lower.contains('avant-centre') || lower.contains('avant centre') || lower.contains('buteur') || lower == 'st' || lower == 'ac') {
    return allTacticalPositions.firstWhere((p) => p.code == 'ST');
  }
  if (lower.contains('second attaquant') || lower == 'ss' || lower == '2ndat') {
    return allTacticalPositions.firstWhere((p) => p.code == 'SS');
  }
  if (lower.contains('attaquant')) {
    return allTacticalPositions.firstWhere((p) => p.code == 'ST');
  }

  return null;
}

/// Les positions regroupées par catégorie pour le sélecteur
Map<String, List<TacticalPosition>> get groupedPositions {
  final map = <String, List<TacticalPosition>>{};
  for (var tp in allTacticalPositions) {
    // Éviter les doublons (CB2, CM2 sont des clones de position)
    if (tp.code == 'CB2' || tp.code == 'CM2') continue;
    map.putIfAbsent(tp.category, () => []).add(tp);
  }
  return map;
}

class TacticalPitchWidget extends StatelessWidget {
  final List<Player> titulaires;
  final Function(Player)? onPlayerTap;

  const TacticalPitchWidget({
    super.key,
    required this.titulaires,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 440,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Pitch Background
            CustomPaint(
              size: const Size(double.infinity, 440),
              painter: _SoccerFieldPainter(),
            ),

            // 2. Header Badge
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '11 DE DÉPART (${titulaires.length}/11)',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A5C36).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      _detectFormation(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Players positioned on pitch
            ...titulaires.map((player) => _buildPositionedPlayer(player)),
          ],
        ),
      ),
    );
  }

  String _detectFormation() {
    int defs = 0, mids = 0, atts = 0;
    for (var p in titulaires) {
      final tp = findTacticalPosition(p.poste);
      if (tp == null) { mids++; continue; }
      switch (tp.category) {
        case 'Défenseur': defs++; break;
        case 'Milieu': mids++; break;
        case 'Attaquant': atts++; break;
      }
    }
    return 'Formation $defs-$mids-$atts';
  }

  Widget _buildPositionedPlayer(Player player) {
    final tp = findTacticalPosition(player.poste);

    // Fallback position if poste unknown
    final double xPct = tp?.x ?? 0.5;
    final double yPct = tp?.y ?? 0.5;
    final Color badgeColor = tp?.color ?? Colors.grey;
    final Color darkColor = HSLColor.fromColor(badgeColor).withLightness(0.25).toColor();
    final String shortLabel = tp?.shortLabel ?? '?';

    final shortName = _formatShortName(player.nom);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use parent constraints for positioning
        return Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: LayoutBuilder(
            builder: (context, boxConstraints) {
              final w = boxConstraints.maxWidth;
              final h = boxConstraints.maxHeight;
              final px = xPct * w - 22; // center the 44px wide node
              final py = yPct * h - 20; // center the node

              return Stack(
                children: [
                  Positioned(
                    left: px.clamp(4, w - 48),
                    top: py.clamp(36, h - 52),
                    child: GestureDetector(
                      onTap: () => onPlayerTap?.call(player),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [badgeColor.withValues(alpha: 0.9), darkColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                shortLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Name tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24, width: 0.5),
                            ),
                            constraints: const BoxConstraints(maxWidth: 78),
                            child: Text(
                              shortName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatShortName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      return parts.last;
    }
    return fullName;
  }
}

/// CustomPainter to draw a realistic football pitch (BeSoccer style)
class _SoccerFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Lush Striped Grass Background
    final darkGrass = const Color(0xFF1E5128);
    final lightGrass = const Color(0xFF194320);

    final Paint grassPaint = Paint()..style = PaintingStyle.fill;

    const int numStripes = 10;
    final double stripeHeight = size.height / numStripes;

    for (int i = 0; i < numStripes; i++) {
      grassPaint.color = (i % 2 == 0) ? darkGrass : lightGrass;
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        grassPaint,
      );
    }

    // 2. Pitch Line Paint
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Paint fillDotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final double margin = 14.0;
    final Rect fieldRect = Rect.fromLTRB(margin, margin, size.width - margin, size.height - margin);
    canvas.drawRect(fieldRect, linePaint);

    // Halfway Line
    final double midY = size.height / 2;
    canvas.drawLine(Offset(margin, midY), Offset(size.width - margin, midY), linePaint);

    // Center Circle
    final double centerRadius = size.width * 0.14;
    canvas.drawCircle(Offset(size.width / 2, midY), centerRadius, linePaint);
    canvas.drawCircle(Offset(size.width / 2, midY), 3.0, fillDotPaint);

    // Top Penalty Area
    final double boxWidth = size.width * 0.52;
    final double boxHeight = size.height * 0.16;
    final double boxLeft = (size.width - boxWidth) / 2;
    canvas.drawRect(Rect.fromLTWH(boxLeft, margin, boxWidth, boxHeight), linePaint);

    // Top Goal Area
    final double smallBoxWidth = size.width * 0.26;
    final double smallBoxHeight = size.height * 0.065;
    final double smallBoxLeft = (size.width - smallBoxWidth) / 2;
    canvas.drawRect(Rect.fromLTWH(smallBoxLeft, margin, smallBoxWidth, smallBoxHeight), linePaint);

    canvas.drawCircle(Offset(size.width / 2, margin + boxHeight - 10), 2.0, fillDotPaint);

    // Bottom Penalty Area
    final double bottomBoxTop = size.height - margin - boxHeight;
    canvas.drawRect(Rect.fromLTWH(boxLeft, bottomBoxTop, boxWidth, boxHeight), linePaint);

    // Bottom Goal Area
    final double bottomSmallBoxTop = size.height - margin - smallBoxHeight;
    canvas.drawRect(Rect.fromLTWH(smallBoxLeft, bottomSmallBoxTop, smallBoxWidth, smallBoxHeight), linePaint);

    canvas.drawCircle(Offset(size.width / 2, size.height - margin - boxHeight + 10), 2.0, fillDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
