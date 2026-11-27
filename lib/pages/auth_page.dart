import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'verify_email_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final idController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool rememberMe = false;
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    String? email;
    try {
      email = await AuthService.resolveEmail(idController.text);
      if (email == null) {
        throw const AuthException('Email/username atau kata sandi salah.');
      }

      await AuthService.signIn(email, passwordController.text);
      final role = await AuthService.getRole();

      if (!mounted) return;
      goToHome(context, role);
    } on AuthException catch (e) {
      if (!mounted) return;
      // Email belum diverifikasi -> kirim ulang kode & arahkan ke halaman verifikasi
      if (e.code == 'email_not_confirmed' && email != null) {
        try {
          await AuthService.resendCode(email);
        } catch (_) {}
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VerifyEmailPage(email: email!)),
        );
      } else {
        setState(() => errorMessage = AuthService.friendlyError(e));
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const HeaderBackground(),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SiminarLogo(),
                        const SizedBox(height: 42),
                        const Text(
                          'SELAMAT DATANG',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Masuk ke SIMINAR',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Temukan dan ciptakan seminar dalam satu akun.',
                          style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                        ),
                        const SizedBox(height: 32),
                        AuthTextField(
                          label: 'Email atau username',
                          hint: 'nama@email.com',
                          icon: Icons.person_outline,
                          controller: idController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Email atau username wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 23),
                        AuthTextField(
                          label: 'Kata sandi',
                          hint: 'Minimal 8 karakter',
                          icon: Icons.shield_outlined,
                          controller: passwordController,
                          obscureText: obscurePassword,
                          suffix: PasswordToggle(
                            obscure: obscurePassword,
                            onToggle: () => setState(
                                () => obscurePassword = !obscurePassword),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Kata sandi wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: rememberMe,
                                activeColor: primaryBlue,
                                onChanged: (v) =>
                                    setState(() => rememberMe = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Ingat saya',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blueGrey),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => showMessage(context,
                                  'Fitur lupa kata sandi belum tersedia.'),
                              child: const Text(
                                'Lupa kata sandi?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        PrimaryButton(
                          text: 'Masuk',
                          loading: loading,
                          onPressed: login,
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'atau',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blueGrey),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                ),
                                child: const Text(
                                  'Daftar sekarang',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: Colors.blueGrey, size: 19),
                              SizedBox(width: 7),
                              Text(
                                'Akses Admin Terotorisasi',
                                style: TextStyle(
                                    color: Colors.blueGrey, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}