import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'home_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const int codeLength = 6;
  static const int resendSeconds = 60;

  final controllers = List.generate(codeLength, (_) => TextEditingController());
  final focusNodes = List.generate(codeLength, (_) => FocusNode());

  Timer? timer;
  int secondsLeft = resendSeconds;
  bool loading = false;
  bool resending = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void startTimer() {
    timer?.cancel();
    setState(() => secondsLeft = resendSeconds);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => secondsLeft = 0);
      } else {
        if (mounted) setState(() => secondsLeft--);
      }
    });
  }

  String get code => controllers.map((c) => c.text).join();

  String get timerText {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void onChanged(int index, String value) {
    // Mendukung paste kode 6 digit
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < codeLength; i++) {
        controllers[i].text = i < digits.length ? digits[i] : '';
      }
      focusNodes[(digits.length.clamp(1, codeLength)) - 1].requestFocus();
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < codeLength - 1) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> verify() async {
    if (code.length != codeLength) {
      showMessage(context, 'Masukkan 6 digit kode verifikasi.', error: true);
      return;
    }

    setState(() => loading = true);
    try {
      await AuthService.verifyEmail(widget.email, code);
      final role = await AuthService.getRole();
      if (!mounted) return;
      showMessage(context, 'Email berhasil diverifikasi!');
      goToHome(context, role);
    } catch (e) {
      if (mounted) {
        showMessage(context, AuthService.friendlyError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resend() async {
    if (secondsLeft > 0 || resending) return;
    setState(() => resending = true);
    try {
      await AuthService.resendCode(widget.email);
      for (final c in controllers) {
        c.clear();
      }
      focusNodes.first.requestFocus();
      startTimer();
      if (mounted) showMessage(context, 'Kode baru telah dikirim.');
    } catch (e) {
      if (mounted) {
        showMessage(context, AuthService.friendlyError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => resending = false);
    }
  }

  Widget codeBox(int i) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: controllers[i],
        focusNode: focusNodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        // Panjang tidak dibatasi 1 agar paste dapat ditangkap di onChanged
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        onChanged: (v) => onChanged(i, v),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6ECF4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
        ),
      ),
    );
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.notifications_none,
                            color: primaryBlue),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'VERIFIKASI EMAIL',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Periksa emailmu',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                              color: Colors.blueGrey, fontSize: 13),
                          children: [
                            const TextSpan(text: 'Kami mengirim kode 6 digit ke '),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(codeLength, codeBox),
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        text: 'Verifikasi Email',
                        loading: loading,
                        onPressed: verify,
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Belum menerima kode? ',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blueGrey),
                            ),
                            GestureDetector(
                              onTap: resend,
                              child: Text(
                                secondsLeft > 0
                                    ? 'Kirim ulang ($timerText)'
                                    : 'Kirim ulang',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: secondsLeft > 0
                                      ? Colors.blueGrey
                                      : primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.popUntil(
                              context, (route) => route.isFirst),
                          child: const Text(
                            'Kembali ke halaman masuk',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
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