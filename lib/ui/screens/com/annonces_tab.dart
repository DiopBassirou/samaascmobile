import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/news_provider.dart';
import '../../../providers/auth_provider.dart';

class AnnoncesTab extends StatefulWidget {
  const AnnoncesTab({super.key});

  @override
  State<AnnoncesTab> createState() => _AnnoncesTabState();
}

class _AnnoncesTabState extends State<AnnoncesTab> {
  final _titreController = TextEditingController();
  final _messageController = TextEditingController();

  Future<void> _publier() async {
    if (_titreController.text.isNotEmpty && _messageController.text.isNotEmpty) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await Provider.of<NewsProvider>(context, listen: false).addNews(
          authProvider,
          _titreController.text, 
          _messageController.text, 
          'INFORMATION'
        );
        _titreController.clear();
        _messageController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce publiée avec succès !', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nouvelle Annonce', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
            child: Column(
              children: [
                TextField(
                  controller: _titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre de l\'annonce',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F8A4B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _publier,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('PUBLIER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text('Historique', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Consumer<NewsProvider>(
            builder: (context, provider, child) {
              return Column(
                children: provider.news.map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(n.type, style: const TextStyle(color: Color(0xFF0F8A4B), fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(n.timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(n.message, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                )).toList(),
              );
            }
          ),
        ],
      ),
    );
  }
}
