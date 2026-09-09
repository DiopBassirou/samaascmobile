import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/asc_provider.dart';
import 'providers/convocation_provider.dart';
import 'providers/rating_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/player_provider.dart';
import 'providers/match_provider.dart';
import 'providers/news_provider.dart';
import 'providers/classement_provider.dart';
import 'providers/poule_provider.dart';
import 'providers/bureau_provider.dart';
import 'ui/screens/auth/splash_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/setup/asc_setup_screen.dart';
import 'ui/shells/main_shell.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  try {
    // Initialisation de Firebase
    await Firebase.initializeApp();
    
    // Demande du Token FCM pour le Web avec la clé VAPID
    final messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken(
      vapidKey: "BKsZ2gbw9SDUmdzi4FU6xSxj2vGYWutGclpuKr-EoSU0O-FoQ2qGoNAPc8AFauA2YnX88x5ozj0eyN7gVa2lZCI",
    );
    print("FCM Token: $token");
  } catch (e) {
    print("Erreur initialisation Firebase: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AscProvider()),
        ChangeNotifierProvider(create: (_) => ConvocationProvider()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => ClassementProvider()),
        ChangeNotifierProvider(create: (_) => PouleProvider()),
        ChangeNotifierProvider(create: (_) => BureauProvider()),
        ChangeNotifierProvider(create: (_) => AscProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAMA ASC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A5C36), // Vert Émeraude
          primary: const Color(0xFF0A5C36),
          secondary: const Color(0xFFFFC107), // Or/Jaune chaud
          surface: Colors.white,
          // ignore: deprecated_member_use
          background: const Color(0xFFF5F5F5),
        ),
        primaryColor: const Color(0xFF0A5C36),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A5C36),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A5C36),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.ascSetup: (context) => const AscSetupScreen(),
        AppRoutes.home: (context) => const MainShell(),
      },
    );
  }
}
