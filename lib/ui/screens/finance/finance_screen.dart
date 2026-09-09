import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/auth_provider.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
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

  void _downloadPdf() async {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final token = await provider.getAuthToken();
    if (token != null) {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
      final Uri url = Uri.parse('$baseUrl/finances/export');
      
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir le fichier.")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bilan Financier', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0F2027)),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.greenAccent)),
                    child: Column(
                      children: [
                        const Text('Solde Actuel', style: TextStyle(color: Colors.white, fontSize: 18)),
                        Text('${provider.solde} FCFA', style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      label: const Text('Télécharger le Bilan (PDF)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: _downloadPdf,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.transactions.length,
                      itemBuilder: (context, index) {
                        final t = provider.transactions[index];
                        final isEntree = t['type'] == 'ENTREE';
                        return ListTile(
                          leading: Icon(isEntree ? Icons.arrow_circle_up : Icons.arrow_circle_down, color: isEntree ? Colors.greenAccent : Colors.redAccent, size: 40),
                          title: Text(t['motif'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(t['date_transaction'], style: const TextStyle(color: Colors.grey)),
                          trailing: Text("${t['montant']} F", style: TextStyle(color: isEntree ? Colors.greenAccent : Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
