import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'auth_page.dart';

/// Arahkan ke Beranda sesuai role (menghapus riwayat halaman sebelumnya)
void goToHome(BuildContext context, String role) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => role == 'admin' ? const AdminHomePage() : const HomePage(),
    ),
    (route) => false,
  );
}

Future<void> _logout(BuildContext context) async {
  await AuthService.signOut();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const AuthPage()),
    (route) => false,
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderHome(title: 'Beranda User', onLogout: () => _logout(context));
  }
}

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderHome(title: 'Dashboard Admin', onLogout: () => _logout(context));
  }
}

class _PlaceholderHome extends StatelessWidget {
  final String title;
  final VoidCallback onLogout;
  const _PlaceholderHome({required this.title, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Login berhasil: $title',
                style: const TextStyle(color: textColor, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onLogout, child: const Text('Keluar')),
          ],
        ),
      ),
    );
  }
}