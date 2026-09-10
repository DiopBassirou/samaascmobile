import 'package:flutter/material.dart';
import '../../../services/asc_service.dart';

class AscListTab extends StatefulWidget {
  const AscListTab({super.key});

  @override
  State<AscListTab> createState() => _AscListTabState();
}

class _AscListTabState extends State<AscListTab> {
  final AscService _ascService = AscService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _ascs = [];

  final _nomController = TextEditingController();
  final _zoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAscs();
  }

  Future<void> _loadAscs() async {
    setState(() => _isLoading = true);
    try {
      final ascs = await _ascService.getSuperAdminAscs();
      if (!mounted) return;
      setState(() => _ascs = ascs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createAsc() async {
    if (_nomController.text.isEmpty || _zoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _ascService.createSuperAdminAsc(
        _nomController.text.trim(),
        _zoneController.text.trim(),
      );
      _nomController.clear();
      _zoneController.clear();
      if (!mounted) return;
      Navigator.pop(context); // Close modal
      await _loadAscs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ASC créée avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouvelle ASC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'ASC',
                  prefixIcon: Icon(Icons.shield),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _zoneController,
                decoration: const InputDecoration(
                  labelText: 'Zone (ex: Zone 1)',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAsc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A5C36),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Créer l\'équipe', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF0A5C36),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Créer ASC', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading && _ascs.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)))
          : RefreshIndicator(
              onRefresh: _loadAscs,
              color: const Color(0xFF0A5C36),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ascs.length,
                itemBuilder: (context, index) {
                  final asc = _ascs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: Text(
                          asc['nom']?.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(color: Color(0xFF0A5C36), fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(asc['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('📍 ${asc['zone'] ?? 'Sans Zone'}', style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.vpn_key, size: 14, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text(
                                  asc['code_unique'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (asc['is_active'] == 1 || asc['is_active'] == true)
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (asc['is_active'] == 1 || asc['is_active'] == true) ? 'Active' : 'Inactif',
                          style: TextStyle(
                            color: (asc['is_active'] == 1 || asc['is_active'] == true) ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
