import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/finance_provider.dart';

class SaisirTab extends StatefulWidget {
  const SaisirTab({super.key});

  @override
  State<SaisirTab> createState() => _SaisirTabState();
}

class _SaisirTabState extends State<SaisirTab> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'DEPENSE';
  final _categorieController = TextEditingController();
  final _montantController = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<FinanceProvider>(context, listen: false).addFinance(
          _type, _categorieController.text, double.parse(_montantController.text)
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction enregistrée avec succès', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          _montantController.clear();
          _categorieController.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<FinanceProvider>(context).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvelle Saisie', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Type Toggle
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _type = 'ENTREE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _type == 'ENTREE' ? const Color(0xFF0A5C36) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _type == 'ENTREE' ? const Color(0xFF0A5C36) : Colors.grey[300]!),
                      ),
                      child: Center(child: Text('ENTRÉE', style: TextStyle(color: _type == 'ENTREE' ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _type = 'DEPENSE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _type == 'DEPENSE' ? const Color(0xFFC62828) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _type == 'DEPENSE' ? const Color(0xFFC62828) : Colors.grey[300]!),
                      ),
                      child: Center(child: Text('DÉPENSE', style: TextStyle(color: _type == 'DEPENSE' ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Form Fields
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
              child: Column(
                children: [
                  TextFormField(
                    controller: _categorieController,
                    decoration: InputDecoration(
                      labelText: 'Désignation (ex: Riz, Eau, Transport)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.description, color: Color(0xFF0A5C36)),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _montantController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant (FCFA)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFF0A5C36)),
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5C36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: isLoading ? null : _submit,
                child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ENREGISTRER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
