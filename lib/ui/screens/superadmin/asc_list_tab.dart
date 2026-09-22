import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
                  final hasLogo = asc['logo_path'] != null && asc['logo_path'].toString().isNotEmpty;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => _showAscActions(asc),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Logo ou initiale
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFFE8F5E9),
                              backgroundImage: hasLogo ? NetworkImage('${_ascService.getBaseUrlWithoutApi()}/storage/${asc['logo_path']}') : null,
                              child: hasLogo ? null : Text(
                                asc['nom']?.substring(0, 1).toUpperCase() ?? 'A',
                                style: const TextStyle(color: Color(0xFF0A5C36), fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(asc['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('📍 ${asc['zone'] ?? 'Sans Zone'}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  const SizedBox(height: 6),
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
                                        Text(asc['code_unique'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (asc['is_active'] == 1 || asc['is_active'] == true) ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (asc['is_active'] == 1 || asc['is_active'] == true) ? 'Active' : 'Inactif',
                                style: TextStyle(color: (asc['is_active'] == 1 || asc['is_active'] == true) ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showAscActions(Map<String, dynamic> asc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(asc['nom'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Code: ${asc['code_unique']}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF0A5C36), child: Icon(Icons.camera_alt, color: Colors.white)),
              title: const Text('Changer le Logo', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Uploader une image depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _uploadLogo(asc['code_unique']);
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: Icon(Icons.person_add, color: Colors.blue.shade700)),
              title: const Text('Ajouter un Joueur', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ajouter un joueur à l\'effectif'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddPlayerDialog(asc);
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Icon(Icons.workspace_premium, color: Colors.orange.shade700)),
              title: const Text('Nommer Président', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(asc['president'] != null ? 'Actuel: ${asc['president']?['prenom'] ?? ''} ${asc['president']?['nom'] ?? ''}' : 'Aucun président assigné'),
              onTap: () {
                Navigator.pop(ctx);
                _showAssignPresidentDialog(asc);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignPresidentDialog(Map<String, dynamic> asc) {
    final codeUnique = asc['code_unique'] as String;
    bool isLoadingUsers = true;
    List<Map<String, dynamic>> users = [];
    int? selectedUserId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // Charger les utilisateurs au premier rendu
          if (isLoadingUsers && users.isEmpty) {
            _ascService.getAscUsers(codeUnique).then((result) {
              setStateDialog(() {
                users = result;
                isLoadingUsers = false;
              });
            }).catchError((e) {
              setStateDialog(() => isLoadingUsers = false);
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text('Président - ${asc['nom']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: isLoadingUsers
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF0A5C36))))
                  : users.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Aucun membre dans cette ASC', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Un utilisateur doit d\'abord rejoindre cette ASC avec le code unique.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final roleName = user['role']?['nom'] ?? 'Supporter';
                            final isPresident = roleName.toUpperCase() == 'PRESIDENT';
                            final isSelected = selectedUserId == user['id'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0A5C36).withValues(alpha: 0.08)
                                    : isPresident
                                        ? Colors.orange.withValues(alpha: 0.06)
                                        : null,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected ? Border.all(color: const Color(0xFF0A5C36), width: 2) : Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isPresident ? Colors.orange.shade100 : const Color(0xFFE8F5E9),
                                  child: Icon(
                                    isPresident ? Icons.workspace_premium : Icons.person,
                                    color: isPresident ? Colors.orange.shade700 : const Color(0xFF0A5C36),
                                    size: 18,
                                  ),
                                ),
                                title: Text('${user['prenom'] ?? ''} ${user['nom'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Row(
                                  children: [
                                    Text('📱 ${user['telephone'] ?? ''}', style: const TextStyle(fontSize: 11)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPresident ? Colors.orange.withValues(alpha: 0.15) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(roleName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPresident ? Colors.orange.shade800 : Colors.grey.shade600)),
                                    ),
                                  ],
                                ),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF0A5C36)) : null,
                                onTap: () => setStateDialog(() => selectedUserId = user['id'] as int),
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
              if (users.isNotEmpty)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.workspace_premium, size: 18),
                  label: const Text('Nommer Président'),
                  onPressed: selectedUserId == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _assignPresident(selectedUserId!, codeUnique);
                        },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _assignPresident(int userId, String codeUnique) async {
    setState(() => _isLoading = true);
    try {
      final result = await _ascService.assignPresident(userId, codeUnique);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Président nommé !'), backgroundColor: Colors.green),
      );
      await _loadAscs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddPlayerDialog(Map<String, dynamic> asc) {
    final nomController = TextEditingController();
    String poste = 'Attaquant';
    final postes = ['Gardien', 'Défenseur', 'Milieu', 'Attaquant'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nouveau joueur - ${asc['nom']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom Complet',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: poste,
                decoration: InputDecoration(
                  labelText: 'Poste',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.sports_soccer),
                ),
                items: postes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setStateDialog(() => poste = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A5C36), foregroundColor: Colors.white),
              onPressed: () async {
                if (nomController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _addPlayer(asc['code_unique'], nomController.text.trim(), poste);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPlayer(String codeUnique, String nom, String poste) async {
    setState(() => _isLoading = true);
    try {
      await _ascService.addSuperAdminPlayer(codeUnique, nom, poste);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joueur $nom ajouté avec succès !'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadLogo(String codeUnique) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);

      if (pickedFile == null) return;

      setState(() => _isLoading = true);
      await _ascService.uploadAscLogo(codeUnique, pickedFile);

      if (!mounted) return;
      await _loadAscs();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo mis à jour !'), backgroundColor: Color(0xFF0A5C36)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }
}
