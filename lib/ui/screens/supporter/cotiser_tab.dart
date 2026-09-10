import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/finance_provider.dart';

class CotiserTab extends StatelessWidget {
  const CotiserTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        double collected = 0;
        for(var t in provider.transactions) {
          if (t['type'] == 'ENTREE' && t['categorie'] == 'Cotisation') {
            collected += double.parse(t['montant'].toString());
          }
        }
        double target = provider.targetCotisation;
        double progress = target > 0 ? collected / target : 0;
        if (progress > 1.0) progress = 1.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Participer à l\'effort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
                child: Column(
                  children: [
                    const Text('Objectif de la saison', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Stack(
                      children: [
                        Container(height: 15, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
                        Container(height: 15, width: MediaQuery.of(context).size.width * 0.7 * progress, decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(10))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${collected.toInt()}F collectés', style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                        Text('${target.toInt()}F', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Montant input
              const Text('Montant à cotiser', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Cotisation hebdomadaire recommandée : 200 FCFA', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: '200'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  suffixText: 'FCFA',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A5C36)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[400]!, width: 1.2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              
              // Payment Buttons
              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B0FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                    // TODO: call provider.payWave(amount)
                },
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Image.asset('assets/images/wave.png', height: 24),
                        const SizedBox(width: 10),
                        const Text('PAYER VIA WAVE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]
                )
              )),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                    // TODO: call provider.payOM(amount)
                },
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Image.asset('assets/images/om.png', height: 24),
                        const SizedBox(width: 10),
                        const Text('PAYER VIA ORANGE MONEY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]
                )
              )),
            ],
          ),
        );
      }
    );
  }
}
