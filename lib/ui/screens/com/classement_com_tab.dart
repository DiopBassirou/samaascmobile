import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sama_asc_mobile/providers/classement_provider.dart';
import 'package:sama_asc_mobile/providers/poule_provider.dart';
import 'package:sama_asc_mobile/providers/auth_provider.dart';
import '../supporter/classement_tab.dart';

class ClassementComTab extends StatefulWidget {
  const ClassementComTab({super.key});

  @override
  State<ClassementComTab> createState() => _ClassementComTabState();
}

class _ClassementComTabState extends State<ClassementComTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Garde le fond de l'application
      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClassementTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.add_chart, color: Colors.white),
        label: const Text('Saisir un autre résultat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showOtherMatchDialog(context),
      ),
    );
  }

  void _showOtherMatchDialog(BuildContext context) {
    // Les équipes sont dans ClassementProvider
    final classementProvider = Provider.of<ClassementProvider>(context, listen: false);
    
    // On filtre "Notre ASC" (qui n'a pas d'id)
    final otherTeams = classementProvider.teams.where((t) => t['id'] != null).toList();

    if (otherTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il faut au moins 2 autres équipes dans la poule.'), backgroundColor: Colors.red),
      );
      return;
    }

    int? team1Id;
    int? team2Id;
    final score1Controller = TextEditingController();
    final score2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Saisir un résultat', style: TextStyle(color: Color(0xFF0A5C36), fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sélectionnez les deux équipes et indiquez leur score pour mettre à jour le classement.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 15),
                    
                    // Équipe 1
                    DropdownButtonFormField<int>(
                      value: team1Id,
                      decoration: InputDecoration(
                        labelText: 'Équipe 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2), borderRadius: BorderRadius.circular(10)),
                      ),
                      items: otherTeams.map((t) {
                        return DropdownMenuItem<int>(
                          value: t['id'] as int,
                          child: Text(t['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => team1Id = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: score1Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Score Équipe 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('CONTRE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),

                    // Équipe 2
                    DropdownButtonFormField<int>(
                      value: team2Id,
                      decoration: InputDecoration(
                        labelText: 'Équipe 2',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2), borderRadius: BorderRadius.circular(10)),
                      ),
                      items: otherTeams.map((t) {
                        return DropdownMenuItem<int>(
                          value: t['id'] as int,
                          child: Text(t['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => team2Id = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: score2Controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Score Équipe 2',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 2), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting ? null : () async {
                    if (team1Id == null || team2Id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner les deux équipes.'), backgroundColor: Colors.red));
                      return;
                    }
                    if (team1Id == team2Id) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les deux équipes doivent être différentes.'), backgroundColor: Colors.red));
                      return;
                    }
                    
                    final s1 = int.tryParse(score1Controller.text);
                    final s2 = int.tryParse(score2Controller.text);

                    if (s1 == null || s2 == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les scores doivent être des nombres valides.'), backgroundColor: Colors.red));
                      return;
                    }
                    
                    setState(() => isSubmitting = true);
                    final pouleProvider = Provider.of<PouleProvider>(context, listen: false);
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    
                    try {
                      await pouleProvider.submitOtherMatchResult(authProvider, team1Id!, team2Id!, s1, s2);
                      
                      // On rafraichit aussi le classement général
                      await Provider.of<ClassementProvider>(context, listen: false).fetchClassement(authProvider);

                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Classement mis à jour avec succès !'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                      }
                    } finally {
                      if (mounted) setState(() => isSubmitting = false);
                    }
                  },
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Valider', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
