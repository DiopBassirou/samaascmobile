import 'package:flutter/material.dart';
// Note: Le service/provider Standings sera implémenté plus tard, on mock pour l'instant.

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classement de la Poule', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0F2027)),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.black.withValues(alpha: 0.3),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Équipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('PTS', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('J', style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('G', style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('N', style: TextStyle(color: Colors.white))),
                  Expanded(child: Text('P', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
            // Mock Data
            _buildRow('1. SAMA ASC', 9, 3, 3, 0, 0),
            _buildRow('2. ASC Jamm', 6, 3, 2, 0, 1),
            _buildRow('3. Mbour FC', 1, 3, 0, 1, 2),
            _buildRow('4. Diaraf', 1, 3, 0, 1, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String name, int pts, int j, int g, int n, int p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text(pts.toString(), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
          Expanded(child: Text(j.toString(), style: const TextStyle(color: Colors.white))),
          Expanded(child: Text(g.toString(), style: const TextStyle(color: Colors.white))),
          Expanded(child: Text(n.toString(), style: const TextStyle(color: Colors.white))),
          Expanded(child: Text(p.toString(), style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
