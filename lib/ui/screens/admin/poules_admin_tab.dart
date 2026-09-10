import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/poule_provider.dart';

class PoulesAdminTab extends StatefulWidget {
  const PoulesAdminTab({super.key});

  @override
  State<PoulesAdminTab> createState() => _PoulesAdminTabState();
}

class _PoulesAdminTabState extends State<PoulesAdminTab> {
  final _pouleNomController = TextEditingController();
  final _pouleZoneController = TextEditingController();
  final List<TextEditingController> _teamControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  String _pouleCategorie = 'SENIOR'; // SENIOR ou CADET

  @override
  void dispose() {
    _pouleNomController.dispose();
    _pouleZoneController.dispose();
    for (var c in _teamControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTeamField() {
    setState(() {
      _teamControllers.add(TextEditingController());
    });
  }

  void _removeTeamField(int index) {
    if (_teamControllers.length > 2) {
      setState(() {
        _teamControllers[index].dispose();
        _teamControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Créer une nouvelle Poule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1929))),
          const SizedBox(height: 16),
          // Nom de la poule
          const Text('Nom de la Poule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
          const SizedBox(height: 8),
          TextField(
            controller: _pouleNomController,
            decoration: InputDecoration(
              hintText: 'Ex: Poule A, Groupe 1...',
              prefixIcon: const Icon(Icons.emoji_events_outlined, color: Color(0xFF0A5C36)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Zone de la Poule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
          const SizedBox(height: 8),
          TextField(
            controller: _pouleZoneController,
            decoration: InputDecoration(
              hintText: 'Ex: Zone 1, Zone 2...',
              prefixIcon: const Icon(Icons.map, color: Color(0xFF0A5C36)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Catégorie de la Poule
          const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _pouleCategorie = 'SENIOR'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _pouleCategorie == 'SENIOR' ? const Color(0xFF0A5C36) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _pouleCategorie == 'SENIOR' ? const Color(0xFF0A5C36) : Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: _pouleCategorie == 'SENIOR' ? Colors.white : Colors.grey[600], size: 18),
                        const SizedBox(width: 6),
                        Text('Seniors', style: TextStyle(fontWeight: FontWeight.bold, color: _pouleCategorie == 'SENIOR' ? Colors.white : Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _pouleCategorie = 'CADET'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _pouleCategorie == 'CADET' ? const Color(0xFF0F8A4B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _pouleCategorie == 'CADET' ? const Color(0xFF0F8A4B) : Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_run, color: _pouleCategorie == 'CADET' ? Colors.white : Colors.grey[600], size: 18),
                        const SizedBox(width: 6),
                        Text('Cadets', style: TextStyle(fontWeight: FontWeight.bold, color: _pouleCategorie == 'CADET' ? Colors.white : Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Équipes adverses
          Row(
            children: [
              const Text('Équipes Adverses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0A5C36).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('${_teamControllers.length} équipes', style: const TextStyle(color: Color(0xFF0A5C36), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Ajoutez les équipes de cette poule', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 16),

          // Team fields
          ...List.generate(_teamControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9)]),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _teamControllers[i],
                      decoration: InputDecoration(
                        hintText: 'Nom de l\'équipe ${i + 1}',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  if (_teamControllers.length > 2) ...[
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                        onPressed: () => _removeTeamField(i),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Add team button
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0A5C36),
                  backgroundColor: const Color(0xFF0A5C36).withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Ajouter une équipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: _addTeamField,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A5C36),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF0A5C36).withValues(alpha: 0.4),
              ),
              onPressed: () async {
                final nom = _pouleNomController.text.trim();
                final zone = _pouleZoneController.text.trim();
                final equipes = _teamControllers
                    .map((c) => c.text.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();

                if (nom.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez donner un nom à la poule'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (zone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner la zone de la poule'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (equipes.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ajoutez au moins 2 équipes'), backgroundColor: Colors.orange),
                  );
                  return;
                }

                try {
                  final pouleProv = Provider.of<PouleProvider>(context, listen: false);
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await pouleProv.createPoule(auth, nom, equipes, zone, categorie: _pouleCategorie);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Poule "$nom" (${ _pouleCategorie == 'CADET' ? 'Cadets' : 'Seniors'}) créée !'), backgroundColor: const Color(0xFF2E7D32)),
                    );
                    _pouleNomController.clear();
                    for (final c in _teamControllers) { c.clear(); }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Enregistrer la Poule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
