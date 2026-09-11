import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sama_asc_mobile/providers/asc_provider.dart';
import 'package:sama_asc_mobile/ui/screens/president/bureau_tab.dart';

class ParametresTab extends StatefulWidget {
  const ParametresTab({super.key});

  @override
  State<ParametresTab> createState() => _ParametresTabState();
}

class _ParametresTabState extends State<ParametresTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AscProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.settings == null) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C36)));
        }

        final settings = provider.settings ?? {};
        final nomAsc = settings['nom_asc'] ?? 'Nom de l\'ASC';
        final ville = settings['ville'] ?? 'Ville';
        final zone = settings['zone'] ?? 'Zone';
        final cotisation = settings['cotisation_objectif'] ?? 250000;
        final logoUrl = settings['logo_url'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paramètres de l\'ASC', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A5C36))),
              const SizedBox(height: 20),
              
              if (logoUrl != null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                      border: Border.all(color: const Color(0xFF0A5C36), width: 2),
                    ),
                  ),
                ),

              _buildSetting(
                icon: Icons.edit,
                title: 'Modifier les informations',
                subtitle: '$nomAsc - $ville ($zone)',
                onTap: () => _showEditInfoDialog(context, nomAsc, ville, zone, int.parse(cotisation.toString())),
              ),
              _buildSetting(
                icon: Icons.photo_camera,
                title: 'Logo de l\'ASC',
                subtitle: 'Changer le logo de l\'association',
                onTap: () => _pickAndUploadLogo(context),
              ),
              _buildSetting(
                icon: Icons.money,
                title: 'Montant cotisation',
                subtitle: 'Objectif global: $cotisation FCFA',
                onTap: () => _showEditCotisationDialog(context, nomAsc, ville, zone, int.parse(cotisation.toString())),
              ),
              _buildSetting(
                icon: Icons.person_add,
                title: 'Gestion des rôles',
                subtitle: 'Gérer les membres du bureau',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Gestion des rôles'), backgroundColor: const Color(0xFF0A5C36), foregroundColor: Colors.white),
                    body: const BureauTab(),
                  )));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isRed = false,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: (isRed ? Colors.red : const Color(0xFF0A5C36)).withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: (isRed ? Colors.red : const Color(0xFF0A5C36)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isRed ? Colors.red : const Color(0xFF0A5C36)),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : null)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ),
      ),
    );
  }

  void _showEditInfoDialog(BuildContext context, String currentNom, String currentVille, String currentZone, int currentCotisation) {
    final nomCtrl = TextEditingController(text: currentNom);
    final villeCtrl = TextEditingController(text: currentVille);
    final zoneCtrl = TextEditingController(text: currentZone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Informations de l\'ASC', style: TextStyle(color: Color(0xFF0A5C36))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom de l\'ASC')),
            TextField(controller: villeCtrl, decoration: const InputDecoration(labelText: 'Ville')),
            TextField(controller: zoneCtrl, decoration: const InputDecoration(labelText: 'Zone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            onPressed: () async {
              final ascProvider = Provider.of<AscProvider>(context, listen: false);
              try {
                await ascProvider.updateSettings(nomCtrl.text, villeCtrl.text, zoneCtrl.text, currentCotisation);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showEditCotisationDialog(BuildContext context, String currentNom, String currentVille, String currentZone, int currentCotisation) {
    final cotisCtrl = TextEditingController(text: currentCotisation.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Objectif Cotisation', style: TextStyle(color: Color(0xFF0A5C36))),
        content: TextField(
          controller: cotisCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Montant global attendu (FCFA)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
            onPressed: () async {
              final ascProvider = Provider.of<AscProvider>(context, listen: false);
              try {
                await ascProvider.updateSettings(currentNom, currentVille, currentZone, int.parse(cotisCtrl.text));
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadLogo(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (context.mounted) {
        final ascProvider = Provider.of<AscProvider>(context, listen: false);
        try {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload en cours...')));
          await ascProvider.uploadLogo(pickedFile);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo mis à jour !'), backgroundColor: Colors.green));
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

}
