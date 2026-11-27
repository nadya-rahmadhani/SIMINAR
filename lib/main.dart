import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vhsjxheyjhiepiiuxvct.supabase.co',
    publishableKey: 'sb_publishable_U1AZbs-ZmpS1bCu4qAhdCQ_o68Qgr3h',
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

/// Jika sesi masih ada -> langsung ke Beranda sesuai role, jika tidak -> Login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (Supabase.instance.client.auth.currentSession == null) {
      return const AuthPage();
    }
    return FutureBuilder<String>(
      future: AuthService.getRole(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) return const AuthPage();
        return snap.data == 'admin' ? const AdminHomePage() : const HomePage();
      },
    );
  }
}