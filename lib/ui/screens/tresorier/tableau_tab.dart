import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/auth_provider.dart';

class TableauTab extends StatefulWidget {
  const TableauTab({super.key});

  @override
  State<TableauTab> createState() => _TableauTabState();
}

class _TableauTabState extends State<TableauTab> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<FinanceProvider>(context, listen: false).fetchFinances(auth);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        double entrees = 0;
        double depenses = 0;
        for (var t in provider.transactions) {
          double m = double.parse(t['montant'].toString());
          if (t['type'] == 'ENTREE') entrees += m;
          if (t['type'] == 'DEPENSE') depenses += m;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('ENTRÉES (TOTAL)', '+${entrees.toInt()}F', const Color(0xFF1B5E20))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('DÉPENSES (TOTAL)', '-${depenses.toInt()}F', Colors.red)),
                ],
              ),
              const SizedBox(height: 25),
              const Text('Dernières Opérations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
                child: provider.transactions.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Aucune transaction.')))
                  : Column(
                      children: provider.transactions.take(5).map((t) {
                        bool isEntree = t['type'] == 'ENTREE';
                        return Column(
                          children: [
                            _buildOp(
                              t['categorie'], 
                              t['date_transaction'] ?? 'N/A', 
                              '${isEntree ? '+' : '-'}${t['montant']}F', 
                              isEntree ? const Color(0xFF1B5E20) : Colors.red, 
                              isEntree ? Icons.arrow_downward : Icons.arrow_upward
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

  static Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  static Widget _buildOp(String title, String subtitle, String amount, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ])),
        Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }
}
