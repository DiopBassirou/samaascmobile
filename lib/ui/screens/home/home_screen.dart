import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../coach/convocation_screen.dart';
import '../supporter/match_list_screen.dart';
import '../finance/finance_screen.dart';
import '../competition/standings_screen.dart';
import '../../widgets/premium_module_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    final String prenom = user?['prenom'] ?? '';
    final String nom = user?['nom'] ?? '';
    final String roleName = user?['role']?['nom'] ?? 'Utilisateur';
    final String ascCode = user?['asc_code'] ?? 'Aucune ASC';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, $prenom', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('$roleName • $ascCode', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Vos modules',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildRoleModules(context, roleName),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoleModules(BuildContext context, String role) {
    List<Widget> modules = [];

    // Modules communs Ã  tous (Optionnel, par ex le classement)
    modules.add(
      PremiumModuleCard(
        title: 'Classement & RÃ©sultats',
        subtitle: 'Suivez le championnat en direct',
        icon: Icons.emoji_events,
        iconColor: Colors.blueAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StandingsScreen())),
      ),
    );

    switch (role.toLowerCase()) {
      case 'coach':
        modules.addAll([
          PremiumModuleCard(
            title: 'GÃ©rer les Convocations',
            subtitle: 'Convoquez vos joueurs pour le match',
            icon: Icons.sports_soccer,
            iconColor: Colors.greenAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConvocationScreen(matchId: 1))),
          ),
          PremiumModuleCard(
            title: 'Mon Effectif',
            subtitle: 'Statistiques et Ã©tat de forme',
            icon: Icons.groups,
            iconColor: Colors.orangeAccent,
            onTap: () => _showNotImplemented(context),
          ),
        ]);
        break;

      case 'tresorier':
        modules.addAll([
          PremiumModuleCard(
            title: 'PÃ´le Financier',
            subtitle: 'Bilans PDF et gestion des caisses',
            icon: Icons.account_balance_wallet,
            iconColor: Colors.redAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
          ),
          PremiumModuleCard(
            title: 'Cotisations',
            subtitle: 'Suivi des paiements des membres',
            icon: Icons.payments,
            iconColor: Colors.yellowAccent,
            onTap: () => _showNotImplemented(context),
          ),
        ]);
        break;

      case 'supporter':
        modules.addAll([
          PremiumModuleCard(
            title: 'Espace Fan (Matchs)',
            subtitle: 'Votez et notez les joueurs',
            icon: Icons.star,
            iconColor: Colors.amberAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchListScreen())),
          ),
          PremiumModuleCard(
            title: 'ActualitÃ©s',
            subtitle: 'Les derniÃ¨res infos du club',
            icon: Icons.article,
            iconColor: Colors.cyanAccent,
            onTap: () => _showNotImplemented(context),
          ),
        ]);
        break;

      case 'president':
        modules.addAll([
          PremiumModuleCard(
            title: 'Tableau de bord Global',
            subtitle: 'Vue d''ensemble de l''ASC',
            icon: Icons.dashboard,
            iconColor: Colors.purpleAccent,
            onTap: () => _showNotImplemented(context),
          ),
          PremiumModuleCard(
            title: 'Validation des DÃ©penses',
            subtitle: 'Approuver les dÃ©penses du trÃ©sorier',
            icon: Icons.gavel,
            iconColor: Colors.redAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
          ),
        ]);
        break;

      case 'charge_com':
        modules.addAll([
          PremiumModuleCard(
            title: 'Gestion des ActualitÃ©s',
            subtitle: 'Publier des infos aux supporters',
            icon: Icons.campaign,
            iconColor: Colors.pinkAccent,
            onTap: () => _showNotImplemented(context),
          ),
        ]);
        break;
        
      case 'superadmin':
        modules.addAll([
          PremiumModuleCard(
            title: 'Administration GÃ©nÃ©rale',
            subtitle: 'Gestion globale du systÃ¨me',
            icon: Icons.admin_panel_settings,
            iconColor: Colors.tealAccent,
            onTap: () => _showNotImplemented(context),
          ),
        ]);
        break;

      default:
        modules.add(
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Aucun module spÃ©cifique n'est configurÃ© pour votre profil.",
              style: TextStyle(color: Colors.white70),
            ),
          )
        );
    }

    return modules;
  }

  void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ce module est en cours de dÃ©veloppement 🚀'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}

