import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sama_asc_mobile/providers/bureau_provider.dart';
import 'package:sama_asc_mobile/providers/auth_provider.dart';

class BureauTab extends StatefulWidget {
  const BureauTab({super.key});

  @override
  State<BureauTab> createState() => _BureauTabState();
}

class _BureauTabState extends State<BureauTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BureauProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.members.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)));
        }

        final members = provider.members;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Membres du Bureau', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36))),
              const SizedBox(height: 10),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text('Ajouter / Modifier un membre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => _showAssignRoleDialog(context),
                ),
              ),
              const SizedBox(height: 20),
              
              if (members.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Aucun membre dans le bureau.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...members.map((m) {
                  final nom = m['nom'] ?? '';
                  final prenom = m['prenom'] ?? '';
                  final role = m['role']?['nom'] ?? 'Inconnu';
                  
                  return InkWell(
                    onTap: () => _showAssignRoleDialog(context, initialUser: m),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: const Color(0xFF0A5C36).withValues(alpha: 0.1)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A5C36).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.workspace_premium, color: Color(0xFF0A5C36), size: 26),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$prenom $nom', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F8A4B).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      role,
                                      style: const TextStyle(color: Color(0xFF0F8A4B), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showAssignRoleDialog(BuildContext context, {Map<String, dynamic>? initialUser}) {
    final searchController = TextEditingController(text: initialUser != null ? initialUser['telephone'] : '');
    int selectedRoleId = initialUser != null ? (initialUser['role_id'] ?? 2) : 2; 
    
    final Map<int, String> roleOptions = {
      2: 'Président',
      3: 'Trésorier',
      4: 'Entraîneur',
      5: 'Chargé de Com'
    };

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isSubmitting = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(initialUser != null ? 'Modifier le rôle' : 'Assigner un rôle', style: const TextStyle(color: Color(0xFF0A5C36), fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Recherchez un supporter par nom ou téléphone pour lui attribuer un rôle au sein du bureau.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 15),
                    Autocomplete<Map<String, dynamic>>(
                      initialValue: TextEditingValue(text: searchController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text == '') {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        final bureauProvider = Provider.of<BureauProvider>(context, listen: false);
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final result = await bureauProvider.searchUsers(authProvider, textEditingValue.text);
                        return result.cast<Map<String, dynamic>>();
                      },
                      displayStringForOption: (Map<String, dynamic> option) => option['telephone'],
                      onSelected: (Map<String, dynamic> selection) {
                        searchController.text = selection['telephone'];
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        if (initialUser != null && controller.text.isEmpty) {
                          controller.text = initialUser['telephone'] ?? '';
                        }
                        searchController.text = controller.text;
                        controller.addListener(() {
                           searchController.text = controller.text;
                        });
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Téléphone ou Nom',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF0A5C36)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2), borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: SizedBox(
                              height: 200,
                              width: MediaQuery.of(context).size.width - 100,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text('${option['prenom']} ${option['nom']}'),
                                    subtitle: Text(option['telephone']),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      value: selectedRoleId,
                      decoration: InputDecoration(
                        labelText: 'Rôle',
                        prefixIcon: const Icon(Icons.badge, color: Color(0xFF0A5C36)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2), borderRadius: BorderRadius.circular(10)),
                      ),
                      items: roleOptions.entries.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedRoleId = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting ? null : () async {
                    if (searchController.text.trim().isEmpty) return;
                    
                    setState(() => isSubmitting = true);
                    final bureauProvider = Provider.of<BureauProvider>(context, listen: false);
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    
                    try {
                      await bureauProvider.assignRole(authProvider, searchController.text.trim(), selectedRoleId);
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rôle assigné avec succès !'), backgroundColor: Colors.green));
                        
                        if (selectedRoleId == 2) {
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                      }
                    } finally {
                      if (mounted) setState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Assigner', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
