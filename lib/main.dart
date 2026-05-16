import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/gamevault_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Aviso: Arquivo .env não encontrado.");
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'COLE_SUA_URL_AQUI_SE_NAO_USAR_ENV',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'COLE_SUA_KEY_AQUI_SE_NAO_USAR_ENV',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'GameVault',
      debugShowCheckedModeBanner: false,
      theme: GameVaultTheme.darkTheme,
      initialRoute: session != null ? '/' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}