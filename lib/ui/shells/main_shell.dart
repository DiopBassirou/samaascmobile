import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sama_asc_mobile/providers/auth_provider.dart';
import 'package:sama_asc_mobile/providers/player_provider.dart';
import 'package:sama_asc_mobile/providers/match_provider.dart';
import 'package:sama_asc_mobile/providers/news_provider.dart';
import 'package:sama_asc_mobile/providers/classement_provider.dart';
import 'package:sama_asc_mobile/providers/poule_provider.dart';
import 'package:sama_asc_mobile/providers/finance_provider.dart';
import 'package:sama_asc_mobile/providers/bureau_provider.dart';
import 'package:sama_asc_mobile/providers/asc_provider.dart';
import 'package:sama_asc_mobile/ui/screens/supporter/classement_tab.dart';
import 'package:sama_asc_mobile/ui/screens/supporter/noter_tab.dart';
import 'package:sama_asc_mobile/ui/screens/supporter/settings_guest_tab.dart';
import 'package:sama_asc_mobile/ui/screens/superadmin/asc_list_tab.dart';
import 'package:sama_asc_mobile/ui/screens/superadmin/superadmin_stats_tab.dart';
import 'package:sama_asc_mobile/ui/widgets/role_header.dart';

// Supporter tabs
import 'package:sama_asc_mobile/ui/screens/supporter/home_tab.dart';
import 'package:sama_asc_mobile/ui/screens/supporter/effectif_tab.dart';
// import 'package:sama_asc_mobile/ui/screens/supporter/cotiser_tab.dart';

// Tresorier tabs
import 'package:sama_asc_mobile/ui/screens/tresorier/tableau_tab.dart';
import 'package:sama_asc_mobile/ui/screens/tresorier/saisir_tab.dart';
import 'package:sama_asc_mobile/ui/screens/tresorier/pdf_tab.dart';

// COM tabs
import 'package:sama_asc_mobile/ui/screens/com/live_tab.dart';
import 'package:sama_asc_mobile/ui/screens/com/effectif_com_tab.dart';
import 'package:sama_asc_mobile/ui/screens/com/annonces_tab.dart';

// President tabs
import 'package:sama_asc_mobile/ui/screens/president/bureau_tab.dart';
import 'package:sama_asc_mobile/ui/screens/president/parametres_tab.dart';
import 'package:sama_asc_mobile/ui/screens/admin/poules_admin_tab.dart';
import 'package:sama_asc_mobile/ui/screens/superadmin/superadmin_matches_tab.dart';

import 'package:sama_asc_mobile/services/device_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _initialized = false;
  Map<String, String>? _favoriteAsc;

  @override
  void initState() {
    super.initState();
    _loadFavoriteAsc();
  }

  Future<void> _loadFavoriteAsc() async {
    final fav = await DeviceService().getFavoriteAsc();
    if (mounted) {
      setState(() {
        _favoriteAsc = fav;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!_initialized) {
      _initialized = true;
      _loadData(auth);
    }
  }

  Future<void> _loadData(AuthProvider auth) async {
    final favAsc = await DeviceService().getFavoriteAsc();
    final favAscCode = favAsc?['code_unique'];

    if (mounted) {
      Provider.of<MatchProvider>(context, listen: false).fetchMatches(auth, favAscCode);
      Provider.of<NewsProvider>(context, listen: false).fetchNews(auth, favAscCode);
      Provider.of<ClassementProvider>(context, listen: false).fetchClassement(auth);
      Provider.of<PouleProvider>(context, listen: false).fetchPoules(auth);
      if (favAscCode != null) {
        Provider.of<PlayerProvider>(context, listen: false).fetchPlayers(auth, favAscCode);
      }
      if (auth.token != null) {
        Provider.of<FinanceProvider>(context, listen: false).fetchFinances(auth);
        Provider.of<BureauProvider>(context, listen: false).fetchBureau(auth);
        if (auth.user?['role']?['nom'] == 'PRESIDENT') {
          Provider.of<AscProvider>(context, listen: false).fetchSettings();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final financeProvider = Provider.of<FinanceProvider>(context);
    final bureauProvider = Provider.of<BureauProvider>(context);
    
    // Si l'utilisateur est connecté, on utilise ses données
    // Si c'est un invité, on utilise son ASC favorite
    final String prenom = user != null ? (user['prenom'] ?? '') : (_favoriteAsc?['nom'] ?? 'Supporter');
    final String nom = user != null ? (user['nom'] ?? '') : '';
    final String roleName = user != null ? (user['role']?['nom'] ?? 'Supporter') : 'Supporter';

    final config = _getRoleConfig(roleName, context, financeProvider, bureauProvider);
    final tabs = config['tabs'] as List<Widget>;
    final navItems = config['navItems'] as List<BottomNavigationBarItem>;
    final primaryColor = config['primaryColor'] as Color;
    final badgeColor = config['badgeColor'] as Color;
    final roleIcon = config['roleIcon'] as IconData;
    final roleLabel = user != null ? (config['roleLabel'] as String) : (_favoriteAsc?['nom'] ?? 'Supporter');
    final stats = config['stats'] as List<StatCardData>;

    // Security to avoid out of bounds when switching roles
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: Column(
        children: [
          RoleHeader(
            prenom: prenom,
            nom: nom,
            roleName: roleName,
            roleLabel: roleLabel,
            primaryColor: primaryColor,
            badgeColor: badgeColor,
            roleIcon: roleIcon,
            stats: stats,
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: navItems,
        ),
      ),
    );
  }

  Map<String, dynamic> _getRoleConfig(String role, BuildContext context, FinanceProvider financeProvider, BureauProvider bureauProvider) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);

    final String effectifCount = playerProvider.players.length.toString();

    switch (role.toLowerCase()) {
      case 'admin':
      case 'super admin':
      case 'superadmin':
      case 'super_admin':
        return {
          'primaryColor': const Color(0xFF0A5C36), // Vert sombre
          'badgeColor': const Color(0xFF0F8A4B), // Vert clair
          'roleIcon': Icons.admin_panel_settings,
          'roleLabel': 'Super Admin',
          'stats': const [
            StatCardData(label: 'ASC GLOBALES', value: 'Zones'),
            StatCardData(label: 'PARAMÈTRES', value: 'Système'),
          ],
          'tabs': const [
            SuperAdminStatsTab(),
            AscListTab(),
            SuperAdminMatchesTab(),
            PoulesAdminTab(),
          ],
          'navItems': const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Gestion ASC'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Matchs'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Poules'),
          ],
        };

      case 'entraineur':
        return {
          'primaryColor': const Color(0xFF0A5C36),
          'badgeColor': const Color(0xFF0F8A4B), // Remplacé le jaune par du vert clair
          'roleIcon': Icons.sports,
          'roleLabel': 'Entraîneur',
          'stats': [
            StatCardData(label: 'EFFECTIF', value: effectifCount),
            StatCardData(label: 'PRÉSENTS', value: '0'), // À faire dynamiquement plus tard
          ],
          'tabs': const [
            EffectifTab(),
            AnnoncesTab(),
          ],
          'navItems': const [
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Effectif'),
            BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Annonces'),
          ],
        };

      case 'tresorier':
        double depenses = 0;
        for (var t in financeProvider.transactions) {
          double m = double.tryParse(t['montant'].toString()) ?? 0;
          if (t['type'] == 'DEPENSE' || t['type'] == 'SORTIE') depenses += m;
        }
        
        return {
          'primaryColor': const Color(0xFF0A5C36),
          'badgeColor': const Color(0xFF0F8A4B),
          'roleIcon': Icons.account_balance,
          'roleLabel': 'Trésorier',
          'stats': [
            StatCardData(label: 'CAISSE', value: '${financeProvider.solde.toInt()}F'),
            StatCardData(label: 'DÉPENSES', value: '${depenses.toInt()}F'),
          ],
          'tabs': const [
            TableauTab(),
            SaisirTab(),
            PdfTab(),
            SupporterHomeTab(),
            EffectifTab(),
          ],
          'navItems': const [
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Finances'),
            BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Saisir'),
            BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: 'Bilan'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Match'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Effectif'),
          ],
        };

      case 'charge de communication':
      case 'charge_com':
      case 'charge_de_com':
        return {
          'primaryColor': const Color(0xFF0A5C36),
          'badgeColor': const Color(0xFF0F8A4B),
          'roleIcon': Icons.campaign,
          'roleLabel': 'Communication',
          'stats': [
            StatCardData(label: 'JOUEURS', value: effectifCount),
            StatCardData(
              label: 'MATCH', 
              value: matchProvider.currentMatch != null 
                  ? 'En cours ⚡' 
                  : (matchProvider.nextMatch != null ? matchProvider.nextMatch!.teamBName : 'Aucun')
            ),
          ],
          'tabs': const [
            LiveTab(),
            EffectifComTab(),
            ClassementTab(),
            AnnoncesTab(),
            // CotiserTab(),
          ],
          'navItems': const [
            BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Effectif'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Classement'),
            BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Annonces'),
            // BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Cotiser'),
          ],
        };

      case 'supporter':
      case 'coach': // Pour tester
        return {
          'primaryColor': const Color(0xFF0A5C36),
          'badgeColor': const Color(0xFF0F8A4B),
          'roleIcon': Icons.favorite,
          'roleLabel': 'Supporter',
          'stats': [
            StatCardData(label: 'MES DONS', value: '0F'),
            StatCardData(
              label: 'PROCHAIN MATCH', 
              value: matchProvider.nextMatch != null 
                  ? matchProvider.nextMatch!.teamBName 
                  : (matchProvider.currentMatch != null ? 'EN COURS' : 'Aucun')
            ),
          ],
          'tabs': const [
            SupporterHomeTab(),
            EffectifTab(),
            ClassementTab(),
            NoterTab(),
            SettingsGuestTab(),
          ],
          'navItems': const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Effectif'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Classement'),
            BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'Noter'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
          ],
        };

      case 'president':
        return {
          'primaryColor': const Color(0xFF0A5C36),
          'badgeColor': const Color(0xFFFFC107),
          'roleIcon': Icons.workspace_premium,
          'roleLabel': 'Président',
          'stats': [
            StatCardData(label: 'MEMBRES BUREAU', value: '${bureauProvider.members.length}'),
            StatCardData(label: 'JOUEURS', value: effectifCount),
          ],
          'tabs': const [
            BureauTab(),
            ParametresTab(),
            SupporterHomeTab(),
            AnnoncesTab(),
            // CotiserTab(),
          ],
          'navItems': const [
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Bureau'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Match'),
            BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Annonces'),
            // BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Cotiser'),
          ],
        };

      default:
        return {
          'primaryColor': const Color(0xFF0A5C36),
          'badgeColor': const Color(0xFF0F8A4B),
          'roleIcon': Icons.person,
          'roleLabel': 'Utilisateur',
          'stats': <StatCardData>[],
          'tabs': const [
            SupporterHomeTab(),
            ClassementTab(),
            SettingsGuestTab(),
          ],
          'navItems': const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Classement'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
          ],
        };
    }
  }
}

