import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/finance_provider.dart';

class PdfTab extends StatefulWidget {
  const PdfTab({super.key});

  @override
  State<PdfTab> createState() => _PdfTabState();
}

class _PdfTabState extends State<PdfTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _activeChip = 'Mois';

  @override
  void initState() {
    super.initState();
    _setPreset('Mois');
  }

  void _setPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _activeChip = preset;
      if (preset == 'Jour') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'Semaine') {
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = _startDate!.add(const Duration(days: 6, hours: 23, minutes: 59));
      } else if (preset == 'Mois') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (preset == 'Année') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      } else {
        _activeChip = 'Custom';
      }
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A5C36),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _activeChip = 'Custom';
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = picked;
          }
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = DateTime(picked.year, picked.month, picked.day);
          }
        }
      });
    }
  }

  void _downloadPdf() async {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final token = await provider.getAuthToken();
    if (token != null) {
      String baseUrl = provider.getExportUrl(token);
      
      if (_startDate != null && _endDate != null) {
        final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
        final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
        baseUrl += '&start_date=$startStr&end_date=$endStr';
      }

      final Uri url = Uri.parse(baseUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir le fichier.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    
    // Calculate preview
    double totalEntrees = 0;
    double totalDepenses = 0;
    List<dynamic> filteredTransactions = [];
    
    for (var t in provider.transactions) {
      try {
        final date = DateTime.parse(t['date_transaction'].toString());
        if (_startDate != null && date.isBefore(_startDate!)) continue;
        if (_endDate != null && date.isAfter(_endDate!)) continue;
        
        filteredTransactions.add(t);
        double m = double.tryParse(t['montant'].toString()) ?? 0;
        if (t['type'] == 'ENTREE') totalEntrees += m;
        if (t['type'] == 'DEPENSE' || t['type'] == 'SORTIE') totalDepenses += m;
      } catch (e) {
        // Ignore invalid dates
      }
    }
    
    final soldeNet = totalEntrees - totalDepenses;
    final dateStr = _startDate != null && _endDate != null
        ? "Du ${DateFormat('dd/MM/yyyy').format(_startDate!)} au ${DateFormat('dd/MM/yyyy').format(_endDate!)}"
        : "Aperçu Global";

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Générer un Bilan PDF', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 15),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _buildChip('Jour'), _buildChip('Semaine'), _buildChip('Mois'), _buildChip('Année')
        ]),
      ),
      const SizedBox(height: 20),
      const Text('Période', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _buildDateBox(true)), 
        const SizedBox(width: 10), 
        Expanded(child: _buildDateBox(false))
      ]),
      const SizedBox(height: 25),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0A5C36))),
          const SizedBox(height: 15),
          _line('Total Entrées', '+${totalEntrees.toInt()} F', const Color(0xFF0A5C36)),
          _line('Total Dépenses', '-${totalDepenses.toInt()} F', Colors.red),
          const Divider(),
          _line('Solde Net', '${soldeNet >= 0 ? '+' : ''}${soldeNet.toInt()} F', soldeNet >= 0 ? const Color(0xFF0A5C36) : Colors.red, bold: true),
        ]),
      ),
      const SizedBox(height: 20),
      const Text('Détail des Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      if (filteredTransactions.isEmpty)
        const Text('Aucune transaction sur cette période', style: TextStyle(color: Colors.grey))
      else
        ...filteredTransactions.map((t) {
          bool isEntree = t['type'] == 'ENTREE';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
            child: Row(
              children: [
                Icon(isEntree ? Icons.arrow_downward : Icons.arrow_upward, color: isEntree ? Colors.green : Colors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['motif'] ?? t['categorie'] ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(t['date_transaction'].toString())), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text('${isEntree ? '+' : '-'}${double.tryParse(t['montant'].toString())?.toInt() ?? 0} F', style: TextStyle(color: isEntree ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A5C36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        icon: const Text('📋', style: TextStyle(fontSize: 18)),
        label: const Text('Télécharger en PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        onPressed: _downloadPdf,
      )),
    ]));
  }

  Widget _buildChip(String label) {
    bool active = _activeChip == label;
    return GestureDetector(
      onTap: () => _setPreset(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: active ? const Color(0xFF0A5C36) : Colors.grey[200], borderRadius: BorderRadius.circular(25), boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)] : null),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildDateBox(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    final hint = isStart ? 'Début' : 'Fin';
    return InkWell(
      onTap: () => _pickDate(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : hint, style: TextStyle(color: date != null ? Colors.black : Colors.grey[600])),
            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0A5C36)),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value, Color color, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: bold ? 16 : 14)),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: bold ? 18 : 16)),
    ]),
  );
}
