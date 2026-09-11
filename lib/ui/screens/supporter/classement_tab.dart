import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/classement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/team_logo.dart';

class ClassementTab extends StatefulWidget {
  const ClassementTab({super.key});

  @override
  State<ClassementTab> createState() => _ClassementTabState();
}

class _ClassementTabState extends State<ClassementTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedZone = ''; // '' = Toutes
  String _selectedCategorie = ''; // '' = Toutes

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final prov = Provider.of<ClassementProvider>(context, listen: false);
      prov.fetchClassement(auth);
      prov.fetchAllMatches(authProvider: auth);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final prov = Provider.of<ClassementProvider>(context, listen: false);
    prov.fetchAllMatches(
      authProvider: auth,
      zone: _selectedZone.isNotEmpty ? _selectedZone : null,
      categorie: _selectedCategorie.isNotEmpty ? _selectedCategorie : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClassementProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // --- Top Tabs ---
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0A5C36), Color(0xFF0F8A4B)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: '📅 Résultats'),
                  Tab(text: '🏆 Classement'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- Filter Chips ---
            _buildFilterChips(provider),

            // --- Tab Content ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResultsTab(provider),
                  _buildClassementTab(provider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(ClassementProvider provider) {
    final zones = ['', ...provider.availableZones];
    final categories = ['', 'SENIOR', 'CADET'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Zone chips
          ...zones.map((z) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(z.isEmpty ? '🌍 Toutes' : '📍 $z', style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selectedZone == z ? Colors.white : Colors.grey[700],
              )),
              selected: _selectedZone == z,
              selectedColor: const Color(0xFF0A5C36),
              backgroundColor: Colors.white,
              side: BorderSide(color: _selectedZone == z ? const Color(0xFF0A5C36) : Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (selected) {
                setState(() => _selectedZone = selected ? z : '');
                _onFilterChanged();
              },
            ),
          )),
          Container(width: 1, height: 28, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 6)),
          // Catégorie chips
          ...categories.map((c) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                c.isEmpty ? 'Tous' : (c == 'SENIOR' ? '🧑 Seniors' : '🏃 Cadets'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _selectedCategorie == c ? Colors.white : Colors.grey[700],
                ),
              ),
              selected: _selectedCategorie == c,
              selectedColor: c == 'CADET' ? const Color(0xFF0F8A4B) : const Color(0xFF0A5C36),
              backgroundColor: Colors.white,
              side: BorderSide(color: _selectedCategorie == c ? const Color(0xFF0A5C36) : Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (selected) {
                setState(() => _selectedCategorie = selected ? c : '');
                _onFilterChanged();
              },
            ),
          )),
        ],
      ),
    );
  }

  // ============================================
  // TAB 1 — RÉSULTATS (BeSoccer style)
  // ============================================
  Widget _buildResultsTab(ClassementProvider provider) {
    if (provider.isLoadingMatches) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)));
    }

    final dates = provider.allMatchDates;
    if (dates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Aucun match trouvé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('Essayez un autre filtre.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final dateGroup = dates[index];
        final label = dateGroup['label'] ?? '';
        final dateStr = dateGroup['date'] ?? '';
        final matches = List<Map<String, dynamic>>.from(dateGroup['matches'] ?? []);
        
        // Trier les matchs : SENIOR en premier, puis CADET si aucune catégorie sélectionnée
        if (_selectedCategorie.isEmpty) {
          matches.sort((a, b) {
            final catA = a['categorie'] ?? 'SENIOR';
            final catB = b['categorie'] ?? 'SENIOR';
            if (catA == 'SENIOR' && catB != 'SENIOR') return -1;
            if (catA != 'SENIOR' && catB == 'SENIOR') return 1;
            return 0;
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0A5C36), Color(0xFF0F8A4B)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),

            // Match cards
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: matches.asMap().entries.map((entry) {
                  final index = entry.key;
                  final m = entry.value;
                  final isLast = index == matches.length - 1;
                  final currentCat = m['categorie'] ?? 'SENIOR';
                  final previousCat = index > 0 ? (matches[index - 1]['categorie'] ?? 'SENIOR') : null;
                  
                  final bool showCategorySeparator = _selectedCategorie.isEmpty && currentCat != previousCat;

                  return Column(
                    children: [
                      if (showCategorySeparator)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          color: Colors.grey[50],
                          child: Row(
                            children: [
                              Icon(currentCat == 'CADET' ? Icons.directions_run : Icons.person, 
                                  color: currentCat == 'CADET' ? const Color(0xFF0F8A4B) : const Color(0xFF0A5C36), size: 14),
                              const SizedBox(width: 6),
                              Text('Matchs $currentCat', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold,
                                color: currentCat == 'CADET' ? const Color(0xFF0F8A4B) : const Color(0xFF0A5C36)
                              )),
                              const Expanded(child: Divider(indent: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      _buildMatchRow(m),
                      if (!isLast) Divider(height: 1, color: Colors.grey[100]),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildMatchRow(Map<String, dynamic> m) {
    final statut = m['statut'] ?? 'A_VENIR';
    final isTermine = statut == 'TERMINE';
    final isLive = statut == 'EN_COURS' || statut == 'MI_TEMPS';
    final isAVenir = statut == 'A_VENIR';
    final categorie = m['categorie'] ?? 'SENIOR';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Categorie badge
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: categorie == 'CADET' ? const Color(0xFF0F8A4B) : const Color(0xFF0A5C36),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          // Home team
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    m['home'] ?? '',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                TeamLogo(
                  teamName: m['home'] ?? '',
                  logoUrl: m['home_logo'],
                  fallbackColor: const Color(0xFF0A5C36),
                  size: 24,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Score
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isLive
                  ? Colors.red.withValues(alpha: 0.1)
                  : isTermine
                      ? const Color(0xFF0A5C36).withValues(alpha: 0.06)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: isLive ? Border.all(color: Colors.red.withValues(alpha: 0.3)) : null,
            ),
            child: Center(
              child: isAVenir
                  ? Text(
                      _formatTime(m['date_match']),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[600]),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLive) Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        Text(
                          '${m['score_home'] ?? 0} - ${m['score_away'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isLive ? Colors.red : const Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Away team
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TeamLogo(
                  teamName: m['away'] ?? '',
                  logoUrl: m['away_logo'],
                  fallbackColor: const Color(0xFF0F8A4B),
                  size: 24,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    m['away'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Poule & Lieu badge
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m['poule'] ?? '',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                ),
              ),
              if (m['lieu'] != null && m['lieu'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 10, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        m['lieu'],
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic dateMatch) {
    if (dateMatch == null) return 'TBD';
    try {
      final dt = DateTime.parse(dateMatch.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'TBD';
    }
  }

  // ============================================
  // TAB 2 — CLASSEMENT (existing, enhanced)
  // ============================================
  Widget _buildClassementTab(ClassementProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)));
    }

    final zonesData = provider.zonesData;
    if (zonesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Aucun classement disponible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    // Filter by zone if selected
    final filteredZones = _selectedZone.isNotEmpty
        ? zonesData.entries.where((e) => e.key == _selectedZone)
        : zonesData.entries;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ...filteredZones.map((zoneEntry) {
          final zoneName = zoneEntry.key;
          final categories = zoneEntry.value as Map<String, dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone header
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0A5C36), Color(0xFF0F8A4B)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(zoneName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // Loop through categories (SENIOR/CADET)
              ...categories.entries.map((catEntry) {
                final catName = catEntry.key; // 'SENIOR' or 'CADET'
                if (_selectedCategorie.isNotEmpty && _selectedCategorie != catName) return const SizedBox();

                final poules = catEntry.value as Map<String, dynamic>;

                return Column(
                  children: [
                    // Category Header (if displaying both)
                    if (_selectedCategorie.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Row(
                          children: [
                            Icon(catName == 'CADET' ? Icons.directions_run : Icons.person, 
                                color: catName == 'CADET' ? const Color(0xFF0F8A4B) : const Color(0xFF0A5C36), size: 18),
                            const SizedBox(width: 8),
                            Text('Classement $catName', style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold,
                              color: catName == 'CADET' ? const Color(0xFF0F8A4B) : const Color(0xFF0A5C36)
                            )),
                            const Expanded(child: Divider(indent: 10, color: Colors.grey)),
                          ],
                        ),
                      ),

                    ...poules.entries.map((pouleEntry) {
                      final pouleName = pouleEntry.key;
                      final teams = List<Map<String, dynamic>>.from(pouleEntry.value);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            // Poule header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A5C36).withValues(alpha: 0.06),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emoji_events, color: Color(0xFF0A5C36), size: 16),
                                  const SizedBox(width: 8),
                                  Text(pouleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0A5C36))),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: catName == 'CADET' ? const Color(0xFF0F8A4B) : const Color(0xFF0A5C36),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(catName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))
                                  ),
                                ],
                              ),
                            ),
                            // Table header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  const SizedBox(width: 28, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11))),
                                  const Expanded(child: Text('ÉQUIPE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11))),
                                  ...['J', 'V', 'N', 'D', 'DB', 'PTS'].map((h) => SizedBox(
                                    width: h == 'PTS' ? 30 : 24,
                                    child: Text(h, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                                  )),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Teams
                            ...teams.map((t) => Container(
                              color: t['highlight'] == true ? const Color(0xFFE8F5E9) : null,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: t['highlight'] == true ? const Color(0xFF4CAF50) : Colors.grey[200],
                                      ),
                                      child: Center(child: Text('${t['rank'] ?? 0}', style: TextStyle(
                                        color: t['highlight'] == true ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold, fontSize: 11,
                                      ))),
                                    ),
                                  ),
                                  Expanded(child: Text('${t['name'] ?? ''}', style: TextStyle(
                                    fontWeight: t['highlight'] == true ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ))),
                                  ...['j', 'v', 'n', 'd', 'db_formatted', 'pts'].map((key) => SizedBox(
                                    width: key == 'pts' ? 30 : 24,
                                    child: Text(
                                      '${t[key] ?? 0}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: key == 'pts' ? FontWeight.bold : FontWeight.normal,
                                        color: key == 'pts' ? const Color(0xFF1B5E20) : null,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            )),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}
