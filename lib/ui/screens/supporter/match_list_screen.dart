import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/rating_provider.dart';
import 'player_rating_screen.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});
  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RatingProvider>(context, listen: false).fetchMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RatingProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Matchs (Zone de Vote)', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0F2027)),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
            : provider.matches.isEmpty
                ? const Center(child: Text("Aucun match disponible.", style: TextStyle(color: Colors.white)))
                : ListView.builder(
                    itemCount: provider.matches.length,
                    itemBuilder: (context, index) {
                      final match = provider.matches[index];
                      return Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: const Icon(Icons.sports_soccer, color: Colors.greenAccent, size: 40),
                          title: Text("Date : ${match['date_match']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text("Statut : ${match['statut']}", style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerRatingScreen(matchId: match['id'])));
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
