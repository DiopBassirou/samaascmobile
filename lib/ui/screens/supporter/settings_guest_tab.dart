import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/device_service.dart';

class SettingsGuestTab extends StatefulWidget {
  const SettingsGuestTab({super.key});

  @override
  State<SettingsGuestTab> createState() => _SettingsGuestTabState();
}

class _SettingsGuestTabState extends State<SettingsGuestTab> {
  Map<String, String>? _favoriteAsc;
  bool _showLoginForm = false;
  bool _showRegisterForm = false;
  bool _isLoading = false;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerPrenomController = TextEditingController();
  final _registerNomController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavoriteAsc();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerPrenomController.dispose();
    _registerNomController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteAsc() async {
    final fav = await DeviceService().getFavoriteAsc();
    if (mounted) setState(() => _favoriteAsc = fav);
  }

  Future<void> _handleLogin() async {
    final phone = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showSnack('Remplis tous les champs');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(phone, password);
      if (mounted) {
        _showSnack('Connexion réussie ! 🎉');
        // Recharger la page principale
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      _showSnack('Erreur : ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final prenom = _registerPrenomController.text.trim();
    final nom = _registerNomController.text.trim();
    final email = _registerEmailController.text.trim();
    final phone = _registerPhoneController.text.trim();
    final password = _registerPasswordController.text.trim();
    final confirm = _registerConfirmController.text.trim();

    if (prenom.isEmpty || nom.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Remplis tous les champs obligatoires');
      return;
    }
    if (password != confirm) {
      _showSnack('Les mots de passe ne correspondent pas');
      return;
    }
    if (password.length < 6) {
      _showSnack('Le mot de passe doit avoir au moins 6 caractères');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(nom, prenom, phone, password);
      if (mounted) {
        _showSnack('Compte créé avec succès ! 🎉');
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      _showSnack('Erreur : ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0A5C36);
    final auth = Provider.of<AuthProvider>(context);
    final isLoggedIn = auth.isAuthenticated;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Mon ASC ===
          _buildSectionTitle('Mon ASC favorite', Icons.favorite),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _favoriteAsc?['nom']?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _favoriteAsc?['nom'] ?? 'Aucune ASC choisie',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _favoriteAsc?['code_unique'] ?? '',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.selectAsc);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Changer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // === Compte ===
          _buildSectionTitle(
            isLoggedIn ? 'Mon compte' : 'Espace membre',
            isLoggedIn ? Icons.person : Icons.lock_outline,
          ),
          const SizedBox(height: 10),

          if (isLoggedIn) ...[
            // Utilisateur connecté : affiche ses infos + déconnexion
            _buildConnectedCard(auth, primaryColor),
          ] else ...[
            // Non connecté : boutons Se connecter / Créer un compte
            if (!_showLoginForm && !_showRegisterForm) ...[
              _buildAuthOption(
                icon: Icons.login,
                title: 'Se connecter avec mon compte',
                subtitle: 'J\'ai déjà un compte membre',
                color: primaryColor,
                onTap: () => setState(() {
                  _showLoginForm = true;
                  _showRegisterForm = false;
                }),
              ),
              const SizedBox(height: 12),
              _buildAuthOption(
                icon: Icons.person_add_outlined,
                title: 'Créer un compte',
                subtitle: 'Devenir membre officiel de mon ASC',
                color: const Color(0xFF1B7A4E),
                onTap: () => setState(() {
                  _showRegisterForm = true;
                  _showLoginForm = false;
                }),
              ),
            ],

            // Formulaire de connexion
            if (_showLoginForm) _buildLoginForm(primaryColor),

            // Formulaire d'inscription
            if (_showRegisterForm) _buildRegisterForm(primaryColor),
          ],

          const SizedBox(height: 28),

          // === À propos ===
          _buildSectionTitle('À propos', Icons.info_outline),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow('Application', 'SAMA ASC'),
                const Divider(height: 20),
                _buildInfoRow('Version', '1.0.0'),
                const Divider(height: 20),
                _buildInfoRow('Ville', 'Mbour, Sénégal'),
                const Divider(height: 20),
                _buildInfoRow('Compétition', 'Navétane Zone 2A'),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0A5C36), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A5C36),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.login, color: Color(0xFF0A5C36), size: 22),
              const SizedBox(width: 8),
              const Text('Connexion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _showLoginForm = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(_loginEmailController, 'Téléphone', Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField(_loginPasswordController, 'Mot de passe', Icons.lock_outline, isPassword: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _showLoginForm = false;
                _showRegisterForm = true;
              }),
              child: const Text(
                'Pas encore de compte ? Créer un compte',
                style: TextStyle(color: Color(0xFF0A5C36), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFF0A5C36), size: 22),
              const SizedBox(width: 8),
              const Text('Créer un compte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _showRegisterForm = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(_registerPrenomController, 'Prénom', Icons.person_outline)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(_registerNomController, 'Nom', Icons.person_outline)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(_registerEmailController, 'Email', Icons.email_outlined),
          const SizedBox(height: 12),
          _buildTextField(_registerPhoneController, 'Téléphone (optionnel)', Icons.phone_outlined),
          const SizedBox(height: 12),
          _buildTextField(_registerPasswordController, 'Mot de passe', Icons.lock_outline, isPassword: true),
          const SizedBox(height: 12),
          _buildTextField(_registerConfirmController, 'Confirmer le mot de passe', Icons.lock_outline, isPassword: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Créer mon compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _showRegisterForm = false;
                _showLoginForm = true;
              }),
              child: const Text(
                'Déjà un compte ? Se connecter',
                style: TextStyle(color: Color(0xFF0A5C36), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard(AuthProvider auth, Color primaryColor) {
    final user = auth.user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${user?['prenom']?[0] ?? ''}${user?['nom']?[0] ?? ''}'.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user?['prenom'] ?? ''} ${user?['nom'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      user?['email'] ?? '',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user?['role']?['nom'] ?? 'Membre',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.selectAsc);
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[300]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF0A5C36), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A5C36), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
