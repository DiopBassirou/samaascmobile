import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TeamLogo extends StatelessWidget {
  final String teamName;
  final String? logoUrl;
  final Color fallbackColor;
  final double size;

  const TeamLogo({
    super.key,
    required this.teamName,
    this.logoUrl,
    required this.fallbackColor,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: logoUrl!,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              color: fallbackColor.withValues(alpha: 0.1),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildFallback(),
          ),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final initial = teamName.isNotEmpty ? teamName[0].toUpperCase() : '?';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: fallbackColor.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: fallbackColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
