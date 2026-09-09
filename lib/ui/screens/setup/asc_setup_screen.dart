import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/asc_provider.dart';
import '../../../core/constants/app_routes.dart';

class AscSetupScreen extends StatefulWidget {
  const AscSetupScreen({super.key});

  @override
  State<AscSetupScreen> createState() => _AscSetupScreenState();
}

class _AscSetupScreenState extends State<AscSetupScreen> {
  final _joinFormKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController.text = 'TOP26'; // Préconfiguré pour Top Jeunesse
  }

  void _submitJoin() async {
    if (_joinFormKey.currentState!.validate()) {
      try {
        await Provider.of<AscProvider>(context, listen: false).joinAsc(_codeController.text);
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AscProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield, size: 80, color: Colors.greenAccent),
                        const SizedBox(height: 20),
                        const Text("Rejoindre votre ASC", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text("Top Jeunesse (Pré-configuré pour aujourd'hui)", style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
                        const SizedBox(height: 40),

                        Form(
                          key: _joinFormKey,
                          child: Column(
                            children: [
                              _buildField(_codeController, "Code de l'ASC", Icons.vpn_key),
                              const SizedBox(height: 30),
                              provider.isLoading
                                  ? const CircularProgressIndicator(color: Colors.greenAccent)
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, minimumSize: const Size(double.infinity, 50)),
                                      onPressed: _submitJoin,
                                      child: const Text("Rejoindre l'équipe", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      readOnly: true, // Empêche la modification du champ
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (value) => value!.isEmpty ? 'Champ requis' : null,
    );
  }
}
