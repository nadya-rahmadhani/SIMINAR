import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// 08xxx / 62xxx / +62xxx -> +62xxx
  static String normalizePhone(String input) {
    var p = input.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('0')) return '+62${p.substring(1)}';
    if (p.startsWith('62')) return '+$p';
    return '+62$p';
  }

  static Future<bool> isUsernameAvailable(String username) async {
    final res = await _client
        .rpc('is_username_available', params: {'p_username': username.trim()});
    return res == true;
  }

  /// Mengembalikan email dari input "email atau username". Null jika tidak ada.
  static Future<String?> resolveEmail(String identifier) async {
    final id = identifier.trim();
    if (id.contains('@')) return id;
    final res =
        await _client.rpc('get_email_by_username', params: {'p_username': id});
    return res as String?;
  }

  static Future<void> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String username,
    required String password,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'username': username.trim(),
        'phone_number': normalizePhone(phone),
      },
    );

    // Email sudah terdaftar & terverifikasi -> Supabase mengembalikan user tanpa identities
    if (res.user != null && (res.user!.identities?.isEmpty ?? false)) {
      throw const AuthException('Email sudah terdaftar. Silakan masuk.');
    }
  }

  static Future<void> verifyEmail(String email, String code) async {
    await _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: code,
    );
  }

  static Future<void> resendCode(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  static Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// 'admin' atau 'user'
  static Future<String> getRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 'user';
    final row = await _client
        .from('users')
        .select('role')
        .eq('user_id', uid)
        .maybeSingle();
    return (row?['role'] as String?)?.toLowerCase() ?? 'user';
  }

  static Future<void> signOut() => _client.auth.signOut();

  /// Pesan error ramah pengguna (Bahasa Indonesia)
  static String friendlyError(Object e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (e.code == 'email_not_confirmed' || msg.contains('not confirmed')) {
        return 'Email belum diverifikasi.';
      }
      if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        return 'Email/username atau kata sandi salah.';
      }
      if (msg.contains('already registered') || msg.contains('sudah terdaftar')) {
        return 'Email sudah terdaftar. Silakan masuk.';
      }
      if (msg.contains('token') && (msg.contains('expired') || msg.contains('invalid'))) {
        return 'Kode salah atau sudah kedaluwarsa.';
      }
      if (msg.contains('rate limit') || e.statusCode == '429') {
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      }
      return e.message;
    }
    if (e is PostgrestException) {
      if (e.code == '23505') return 'Username atau data sudah digunakan.';
      return 'Terjadi kesalahan pada server.';
    }
    return 'Terjadi kesalahan. Periksa koneksi internet kamu.';
  }
}