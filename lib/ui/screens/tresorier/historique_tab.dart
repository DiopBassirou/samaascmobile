import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/finance_provider.dart';

class HistoriqueTab extends StatelessWidget {
  const HistoriqueTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Historique Complet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
                child: provider.transactions.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Aucune transaction.')))
                  : Column(
                      children: provider.transactions.map((t) {
                        bool isEntree = t['type'] == 'ENTREE';
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: isEntree ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), 
                                    borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Icon(isEntree ? Icons.arrow_downward : Icons.arrow_upward, color: isEntree ? Colors.green : Colors.red, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t['categorie'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(t['date_transaction'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ])),
                                Text('${isEntree ? '+' : '-'}${t['montant']}F', style: TextStyle(color: isEntree ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                              ]),
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                    ),
              ),
            ],
          ),
        );
      }
    );
  }
}
