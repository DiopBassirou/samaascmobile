import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/asc_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/asc_service.dart';

class AscSetupScreen extends StatefulWidget {
  const AscSetupScreen({super.key});

  @override
  State<AscSetupScreen> createState() => _AscSetupScreenState();
}

class _AscSetupScreenState extends State<AscSetupScreen> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  // Étape 1 : Compte
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Étape 2 : Choix de l'ASC
  final _codeController = TextEditingController();
  List<Map<String, dynamic>> _ascList = [];
  Map<String, dynamic>? _selectedAsc;
  bool _useCode = false; // basculer entre liste déroulante et code manuel
  bool _loadingAscs = false;

  int _currentStep = 1; // 1 = infos perso, 2 = choix ASC

  @override
  void initState() {
    super.initState();
    _loadAscs();
  }

  Future<void> _loadAscs() async {
    setState(() => _loadingAscs = true);
    try {
      final ascs = await AscService().getValidatedAscs();
      setState(() => _ascList = ascs);
    } catch (_) {
      // En cas d'erreur, on affiche juste le mode "code"
      setState(() => _useCode = true);
    } finally {
      setState(() => _loadingAscs = false);
    }
  }

  Future<void> _submitStep1() async {
    if (_formKeyStep1.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.register(
          _nomController.text.trim(),
          _prenomController.text.trim(),
          _telephoneController.text.trim(),
          _passwordController.text,
        );
        setState(() => _currentStep = 2);
      } catch (e) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _submitStep2() async {
    if (_formKeyStep2.currentState!.validate()) {
      final ascProvider = Provider.of<AscProvider>(context, listen: false);
      final code = _useCode
          ? _codeController.text.trim()
          : (_selectedAsc?['code_unique'] ?? '');

      if (code.isEmpty) {
        _showError('Veuillez sélectionner ou saisir votre équipe');
        return;
      }
      try {
        await ascProvider.joinAsc(code);
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
      } catch (e) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
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
              // Header avec retour et indicateur d'étape
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (_currentStep == 2) {
                          setState(() => _currentStep = 1);
                        } else {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        }
                      },
                    ),
                    const Spacer(),
                    // Indicateur d'étape
                    _buildStepIndicator(1),
                    Container(width: 40, height: 2, color: _currentStep == 2 ? Colors.greenAccent : Colors.white24),
                    _buildStepIndicator(2),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
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

  Widget _buildStepIndicator(int step) {
    final active = _currentStep >= step;
    return CircleAvatar(
      radius: 16,
      backgroundColor: active ? Colors.greenAccent : Colors.white24,
      child: Text(
        '$step',
        style: TextStyle(
          color: active ? Colors.black : Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      children: [
        const Icon(Icons.person_add_alt_1, size: 70, color: Colors.greenAccent),
        const SizedBox(height: 16),
        const Text("Créer mon compte", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text("Étape 1 sur 2", style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
        const SizedBox(height: 36),
        Form(
          key: _formKeyStep1,
          child: Column(
            children: [
              _buildField(_prenomController, "Prénom", Icons.person_outline),
              const SizedBox(height: 14),
              _buildField(_nomController, "Nom", Icons.person),
              const SizedBox(height: 14),
              _buildField(_telephoneController, "Téléphone", Icons.phone_android, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _buildField(_passwordController, "Mot de passe", Icons.lock_outline, isPassword: true),
              const SizedBox(height: 28),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.greenAccent)
                    : _buildButton("Continuer →", _submitStep1),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text("J'ai déjà un compte", style: TextStyle(color: Colors.white60)),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      children: [
        const Icon(Icons.shield, size: 70, color: Colors.greenAccent),
        const SizedBox(height: 16),
        const Text("Choisir mon équipe", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text("Étape 2 sur 2", style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
        const SizedBox(height: 36),
        Form(
          key: _formKeyStep2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle : Liste ↔ Code manuel
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleBtn("Choisir dans la liste", !_useCode, () => setState(() { _useCode = false; })),
                  const SizedBox(width: 10),
                  _buildToggleBtn("J'ai un code", _useCode, () => setState(() { _useCode = true; })),
                ],
              ),
              const SizedBox(height: 20),

              if (!_useCode) ...[
                if (_loadingAscs)
                  const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                else if (_ascList.isEmpty)
                  const Center(child: Text("Aucune équipe disponible.", style: TextStyle(color: Colors.white60)))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedAsc,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF203A43),
                        hint: const Text("Sélectionner votre équipe ASC", style: TextStyle(color: Colors.white60)),
                        icon: const Icon(Icons.expand_more, color: Colors.greenAccent),
                        items: _ascList.map((asc) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: asc,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(asc['nom'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(asc['zone'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedAsc = val),
                      ),
                    ),
                  ),
              ] else ...[
                _buildField(_codeController, "Code de l'équipe (ex: TOP26)", Icons.vpn_key),
              ],

              const SizedBox(height: 28),
              Consumer<AscProvider>(
                builder: (context, asc, _) => asc.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                    : _buildButton("Rejoindre l'équipe ✓", _submitStep2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.greenAccent : Colors.white12,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.greenAccent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Champ requis' : null,
    );
  }
}
