import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function() codeSent,
    required Function(AuthException error) verificationFailed,
  }) async {
    try {
      await _client.auth.signInWithOtp(
        phone: phoneNumber.startsWith('+') ? phoneNumber : '+88$phoneNumber',
      );
      codeSent();
    } on AuthException catch (error) {
      verificationFailed(error);
    }
  }

  Future<User?> signInWithOtp(String phoneNumber, String smsCode) async {
    final AuthResponse res = await _client.auth.verifyOTP(
      type: OtpType.sms,
      token: smsCode,
      phone: phoneNumber.startsWith('+') ? phoneNumber : '+88$phoneNumber',
    );
    return res.user;
  }

  User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
