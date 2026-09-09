import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import 'dart:ui';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _telephoneController.text.trim(),
          _passwordController.text,
        );
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
      } catch (e) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (math.sin(_animController.value * 2 * math.pi) * 50),
                    left: -100 + (math.cos(_animController.value * 2 * math.pi) * 50),
                    child: Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                    ),
                  ),
                  Positioned(
                    bottom: -150 + (math.cos(_animController.value * 2 * math.pi) * 50),
                    right: -100 + (math.sin(_animController.value * 2 * math.pi) * 50),
                    child: Container(
                      width: 400, height: 400,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
                    ),
                  ),
                ],
              );
            }
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF059669)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.sports_soccer, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  
                  const Text('Bon retour', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('Connectez-vous pour continuer', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _telephoneController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Téléphone',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                              prefixIcon: Icon(Icons.phone_outlined, color: Colors.white.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                            ),
                            validator: (value) => value!.isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Mot de passe',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.6)),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white.withValues(alpha: 0.6)),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                            ),
                            validator: (value) => value!.isEmpty ? 'Requis' : null,
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                              ),
                              onPressed: isLoading ? null : _submit,
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                    : const Text('Se connecter', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.ascSetup),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: "Vous n'avez pas de compte ? ",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                        children: const [
                          TextSpan(text: "S'inscrire", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
