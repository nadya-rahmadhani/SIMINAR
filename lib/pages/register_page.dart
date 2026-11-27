import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeTerms = false;
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    if (!agreeTerms) {
      showMessage(
        context,
        'Silakan setujui Syarat Layanan dan Kebijakan Privasi.',
        error: true,
      );
      return;
    }

    setState(() => loading = true);
    try {
      final available =
          await AuthService.isUsernameAvailable(usernameController.text);
      if (!available) {
        if (mounted) {
          showMessage(context, 'Username sudah digunakan.', error: true);
        }
        return;
      }

      await AuthService.signUp(
        fullName: nameController.text,
        phone: phoneController.text,
        email: emailController.text,
        username: usernameController.text,
        password: passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(email: emailController.text.trim()),
        ),
      );
    } catch (e) {
      if (mounted) {
        showMessage(context, AuthService.friendlyError(e), error: true);
      }
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
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 25),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back,
                              color: darkBlue, size: 22),
                        ),
                        const SizedBox(height: 8),
                        const SiminarLogo(),
                        const SizedBox(height: 30),
                        const Text(
                          'BUAT AKUN USER',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Mulai perjalananmu',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Satu akun untuk mengikuti dan mengelola seminar.',
                          style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                        ),
                        const SizedBox(height: 30),
                        AuthTextField(
                          label: 'Nama lengkap',
                          hint: 'Nama sesuai identitas',
                          icon: Icons.person_outline,
                          controller: nameController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nama lengkap wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'Nomor telepon',
                          hint: '+62 812 3456 7890',
                          icon: Icons.phone_outlined,
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nomor telepon wajib diisi';
                            }
                            final p = v.trim().replaceAll(RegExp(r'[\s-]'), '');
                            if (!RegExp(r'^\+?[0-9]+$').hasMatch(p)) {
                              return 'Nomor telepon tidak valid';
                            }
                            if (p.length < 10 || p.length > 15) {
                              return 'Nomor telepon harus 10–15 digit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'Email',
                          hint: 'nama@email.com',
                          icon: Icons.email_outlined,
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim())) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'Username',
                          hint: 'Pilih username',
                          icon: Icons.alternate_email,
                          controller: usernameController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Username wajib diisi';
                            }
                            if (v.trim().length < 4) {
                              return 'Username minimal 4 karakter';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9_.]+$')
                                .hasMatch(v.trim())) {
                              return 'Hanya huruf, angka, titik, dan underscore';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'Kata sandi',
                          hint: 'Min. 8 karakter, huruf & angka',
                          icon: Icons.lock_outline,
                          controller: passwordController,
                          obscureText: obscurePassword,
                          suffix: PasswordToggle(
                            obscure: obscurePassword,
                            onToggle: () => setState(
                                () => obscurePassword = !obscurePassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Kata sandi wajib diisi';
                            }
                            if (v.length < 8) {
                              return 'Kata sandi minimal 8 karakter';
                            }
                            if (!RegExp(r'[A-Za-z]').hasMatch(v) ||
                                !RegExp(r'[0-9]').hasMatch(v)) {
                              return 'Harus mengandung huruf dan angka';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'Konfirmasi kata sandi',
                          hint: 'Ulangi kata sandi',
                          icon: Icons.lock_reset_outlined,
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          suffix: PasswordToggle(
                            obscure: obscureConfirmPassword,
                            onToggle: () => setState(() =>
                                obscureConfirmPassword =
                                    !obscureConfirmPassword),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Konfirmasi kata sandi wajib diisi';
                            }
                            if (v != passwordController.text) {
                              return 'Kata sandi tidak sama';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: agreeTerms,
                                activeColor: primaryBlue,
                                onChanged: (v) =>
                                    setState(() => agreeTerms = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.blueGrey),
                                  children: [
                                    TextSpan(text: 'Saya menyetujui '),
                                    TextSpan(
                                      text: 'Syarat Layanan',
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Kebijakan Privasi',
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' SIMINAR.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        PrimaryButton(
                          text: 'Daftar sebagai USER',
                          loading: loading,
                          onPressed: register,
                        ),
                        const SizedBox(height: 25),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Sudah punya akun? ',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blueGrey),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Masuk',
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