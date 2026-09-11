import 'package:flutter/material.dart';
import 'package:sama_asc_mobile/core/constants/app_routes.dart';
import 'package:sama_asc_mobile/services/asc_service.dart';
import 'package:sama_asc_mobile/services/device_service.dart';

class SelectAscScreen extends StatefulWidget {
  const SelectAscScreen({super.key});

  @override
  State<SelectAscScreen> createState() => _SelectAscScreenState();
}

class _SelectAscScreenState extends State<SelectAscScreen>
    with SingleTickerProviderStateMixin {
  final AscService _ascService = AscService();
  final DeviceService _deviceService = DeviceService();

  List<Map<String, dynamic>> _ascs = [];
  List<Map<String, dynamic>> _filteredAscs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedAsc;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _loadAscs();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAscs() async {
    setState(() => _isLoading = true);
    try {
      final list = await _ascService.getValidatedAscs();
      if (mounted) {
        setState(() {
          _ascs = list;
          _filteredAscs = list;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  void _filterAscs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredAscs = _ascs;
      } else {
        _filteredAscs = _ascs.where((asc) {
          final nom = (asc['nom'] ?? '').toString().toLowerCase();
          final zone = (asc['zone'] ?? '').toString().toLowerCase();
          final ville = (asc['ville'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return nom.contains(q) || zone.contains(q) || ville.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedAsc == null) return;
    await _deviceService.saveFavoriteAsc(_selectedAsc!);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  String _getInitials(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nom.substring(0, nom.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getAscColor(int index) {
    final colors = [
      const Color(0xFF0A5C36),
      const Color(0xFF1B7A4E),
      const Color(0xFF2E8B57),
      const Color(0xFF3CB371),
      const Color(0xFF006B3F),
      const Color(0xFF228B22),
      const Color(0xFF0D6B3D),
      const Color(0xFF14532D),
      const Color(0xFF166534),
      const Color(0xFF15803D),
      const Color(0xFF16A34A),
      const Color(0xFF22C55E),
      const Color(0xFF047857),
      const Color(0xFF059669),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0A5C36);
    const goldColor = Color(0xFFFFC107);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Column(
        children: [
          // ===== HERO SECTION =====
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A5C36), Color(0xFF0D7A4A), Color(0xFF10945B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  children: [
                    // Logo + Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.sports_soccer,
                              color: primaryColor,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SAMA ASC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Navétane en direct',
                              style: TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Welcome message
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '👋 Bienvenue !',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choisis ton ASC favorite pour suivre\nles scores en direct et les actualités',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: _filterAscs,
                        decoration: InputDecoration(
                          hintText: 'Rechercher une ASC...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: primaryColor),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _filterAscs('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== COUNT BADGE =====
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filteredAscs.length} équipe${_filteredAscs.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedAsc != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: goldColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: primaryColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _selectedAsc!['nom'],
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // ===== ASC GRID =====
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'Chargement des équipes...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _filteredAscs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucune ASC disponible'
                                  : 'Aucun résultat pour "$_searchQuery"',
                              style:
                                  TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: size.width > 600 ? 3 : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: _filteredAscs.length,
                            itemBuilder: (context, index) {
                              final asc = _filteredAscs[index];
                              final isSelected = _selectedAsc?['code_unique'] ==
                                  asc['code_unique'];
                              final logoUrl = asc['logo_url'];
                              final nom = asc['nom'] ?? 'ASC';
                              final zone = asc['zone'] ?? '';
                              final ascColor = _getAscColor(index);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAsc = asc;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withValues(alpha: 0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? primaryColor.withValues(alpha: 0.15)
                                            : Colors.black.withValues(alpha: 0.04),
                                        blurRadius: isSelected ? 12 : 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Selection check
                                      if (isSelected)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),

                                      // Card content
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Avatar / Logo
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  color: ascColor.withValues(alpha: 0.12),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: ascColor.withValues(alpha: 0.3),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: ClipOval(
                                                  child: (logoUrl != null &&
                                                          logoUrl
                                                              .toString()
                                                              .isNotEmpty)
                                                      ? Image.network(
                                                          logoUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context,
                                                              error,
                                                              stackTrace) {
                                                            return Center(
                                                              child: Text(
                                                                _getInitials(nom),
                                                                style: TextStyle(
                                                                  color: ascColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  fontSize: 18,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : Center(
                                                          child: Text(
                                                            _getInitials(nom),
                                                            style: TextStyle(
                                                              color: ascColor,
                                                              fontWeight:
                                                                  FontWeight.w900,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              // Nom ASC
                                              Text(
                                                nom,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected
                                                      ? primaryColor
                                                      : Colors.black87,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              // Zone badge
                                              if (zone.isNotEmpty)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    zone,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),

      // ===== BOTTOM VALIDATE BUTTON =====
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedAsc != null ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey.shade500,
                elevation: _selectedAsc != null ? 4 : 0,
                shadowColor: primaryColor.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedAsc != null
                        ? Icons.check_circle_outline
                        : Icons.touch_app_outlined,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selectedAsc != null
                        ? 'Valider — ${_selectedAsc!['nom']}'
                        : 'Choisis ton ASC pour continuer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
