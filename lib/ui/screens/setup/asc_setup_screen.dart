import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/asc_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';

class AscSetupScreen extends StatefulWidget {
  const AscSetupScreen({super.key});

  @override
  State<AscSetupScreen> createState() => _AscSetupScreenState();
}

class _AscSetupScreenState extends State<AscSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submitJoin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final ascProvider = Provider.of<AscProvider>(context, listen: false);
      
      try {
        // 1. Inscription + Connexion
        await authProvider.register(
          _nomController.text.trim(),
          _prenomController.text.trim(),
          _telephoneController.text.trim(),
          _passwordController.text,
        );
        
        // 2. Rejoindre Top Jeunesse (TOP26)
        if (mounted) {
          await ascProvider.joinAsc('TOP26');
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } catch (e) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
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
                        const Text("Inscription", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text("Rejoindre l'ASC Top Jeunesse", style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 40),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildField(_prenomController, "Prénom", Icons.person_outline),
                              const SizedBox(height: 15),
                              _buildField(_nomController, "Nom", Icons.person),
                              const SizedBox(height: 15),
                              _buildField(_telephoneController, "Téléphone", Icons.phone_android, keyboardType: TextInputType.phone),
                              const SizedBox(height: 15),
                              _buildField(_passwordController, "Mot de passe", Icons.lock_outline, isPassword: true),
                              const SizedBox(height: 30),
                              
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) => (auth.isLoading || provider.isLoading)
                                  ? const CircularProgressIndicator(color: Colors.greenAccent)
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, minimumSize: const Size(double.infinity, 50)),
                                      onPressed: _submitJoin,
                                      child: const Text("Créer mon compte et rejoindre", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                                    )
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

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
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
