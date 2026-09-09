import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/rating_provider.dart';

class PlayerRatingScreen extends StatefulWidget {
  final int matchId;
  const PlayerRatingScreen({super.key, required this.matchId});
  @override
  State<PlayerRatingScreen> createState() => _PlayerRatingScreenState();
}

class _PlayerRatingScreenState extends State<PlayerRatingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RatingProvider>(context, listen: false).fetchPlayersForMatch(widget.matchId);
    });
  }

  void _submit() async {
    try {
      await Provider.of<RatingProvider>(context, listen: false).submitAllRatings(widget.matchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Vos notes ont été enregistrées anonymement !'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RatingProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Noter les joueurs', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0A5C36)),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0A5C36), Color(0xFF094025)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: provider.isLoading && provider.players.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.players.length,
                      itemBuilder: (context, index) {
                        final player = provider.players[index];
                        final rating = provider.ratings[player['id']] ?? 5.0;
                        return Card(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          margin: const EdgeInsets.only(bottom: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${player['nom']} (${player['poste'] ?? 'Poste inconnu'})", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(rating.toInt().toString(), style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 2,
                                        children: List.generate(5, (starIndex) {
                                          return GestureDetector(
                                            onTap: () {
                                              provider.updateRating(player['id'], (starIndex + 1).toDouble());
                                            },
                                            child: Icon(
                                              Icons.star,
                                              color: (starIndex + 1) <= rating ? Colors.amber : Colors.white.withValues(alpha: 0.3),
                                              size: 28, // Légèrement plus grand puisqu'il y en a moins
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
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
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: provider.isLoading ? null : _submit,
                        child: provider.isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('VALIDER MES VOTES', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
