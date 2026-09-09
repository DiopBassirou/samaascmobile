import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/convocation_provider.dart';

class ConvocationScreen extends StatefulWidget {
  final int matchId;
  const ConvocationScreen({super.key, required this.matchId});

  @override
  State<ConvocationScreen> createState() => _ConvocationScreenState();
}

class _ConvocationScreenState extends State<ConvocationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConvocationProvider>(context, listen: false).fetchPlayers();
    });
  }

  void _submit() async {
    try {
      await Provider.of<ConvocationProvider>(context, listen: false).submit(widget.matchId);
      if (mounted) {
        // Simuler la notification PUSH
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔔 Notification envoyée : Le 11 de départ est publié !'),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ConvocationProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sélection du 11 Partant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: provider.isLoading && provider.players.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
            : Column(
                children: [
                  const SizedBox(height: 100),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.players.length,
                      itemBuilder: (context, index) {
                        final player = provider.players[index];
                        final status = provider.selections[player['id']] ?? 'REPOS';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.person, color: Colors.black)),
                            title: Text("${player['prenom']} ${player['nom']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text("Poste: ${player['poste'] ?? 'Non défini'}", style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                            trailing: DropdownButton<String>(
                              value: status,
                              dropdownColor: const Color(0xFF203A43),
                              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                              underline: Container(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  provider.updateSelection(player['id'], newValue);
                                }
                              },
                              items: const [
                                DropdownMenuItem(value: 'TITULAIRE', child: Text('Titulaire')),
                                DropdownMenuItem(value: 'REMPLACANT', child: Text('Remplaçant')),
                                DropdownMenuItem(value: 'REPOS', child: Text('Repos', style: TextStyle(color: Colors.grey))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: provider.isLoading ? null : _submit,
                        child: provider.isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('PUBLIER LA COMPOSITION', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
