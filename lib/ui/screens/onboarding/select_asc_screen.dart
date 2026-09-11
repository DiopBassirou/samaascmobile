import 'package:flutter/material.dart';
import 'package:sama_asc_mobile/core/constants/app_routes.dart';
import 'package:sama_asc_mobile/services/asc_service.dart';
import 'package:sama_asc_mobile/services/device_service.dart';

class SelectAscScreen extends StatefulWidget {
  const SelectAscScreen({super.key});

  @override
  State<SelectAscScreen> createState() => _SelectAscScreenState();
}

class _SelectAscScreenState extends State<SelectAscScreen> {
  final AscService _ascService = AscService();
  final DeviceService _deviceService = DeviceService();

  List<Map<String, dynamic>> _ascs = [];
  List<Map<String, dynamic>> _filteredAscs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedAsc;

  @override
  void initState() {
    super.initState();
    _loadAscs();
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    if (_selectedAsc != null) {
      await _deviceService.saveFavoriteAsc(_selectedAsc!);
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0A5C36);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.sports_soccer,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'SAMA ASC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choisis ton ASC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reçois les scores en direct et les actualités de ton équipe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: _filterAscs,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une ASC, zone...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ASC List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryColor))
                  : _filteredAscs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sports_soccer_outlined, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Aucune ASC disponible pour le moment'
                                    : 'Aucune ASC ne correspond à "$_searchQuery"',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _filteredAscs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final asc = _filteredAscs[index];
                            final isSelected = _selectedAsc?['code_unique'] == asc['code_unique'];
                            final logoUrl = asc['logo_url'];
                            final nom = asc['nom'] ?? 'ASC';
                            final zone = asc['zone'] ?? '';
                            final ville = asc['ville'] ?? '';

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAsc = asc;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? primaryColor.withValues(alpha: 0.12)
                                          : Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Logo ASC
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300, width: 1),
                                      ),
                                      child: ClipOval(
                                        child: (logoUrl != null && logoUrl.toString().isNotEmpty)
                                            ? Image.network(
                                                logoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.shield,
                                                  color: primaryColor,
                                                  size: 28,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.shield,
                                                color: primaryColor,
                                                size: 28,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? primaryColor : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              if (zone.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Zone $zone',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.green.shade800,
                                                    ),
                                                  ),
                                                ),
                                              if (zone.isNotEmpty && ville.isNotEmpty)
                                                const SizedBox(width: 6),
                                              if (ville.isNotEmpty)
                                                Text(
                                                  ville,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Radio check
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? primaryColor : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? primaryColor : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      // Bottom validate button
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedAsc != null ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: _selectedAsc != null ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _selectedAsc != null
                      ? 'Valider ${_selectedAsc!['nom']}'
                      : 'Sélectionnez une ASC',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
              child: Text(
                'Passer pour l\'instant',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
