import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:amar_uddokta/uddoktaa/models/user.dart' as AppUser;
import 'package:amar_uddokta/uddoktaa/services/user_service.dart';

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

  Future<AppUser.User?> signInWithOtp(
      String phoneNumber, String smsCode) async {
    final AuthResponse res = await _client.auth.verifyOTP(
      type: OtpType.sms,
      token: smsCode,
      phone: phoneNumber.startsWith('+') ? phoneNumber : '+88$phoneNumber',
    );

    if (res.user != null) {
      final UserService _userService = UserService();
      // Check if user exists in our 'users' table, if not, create one
      AppUser.User? appUser = await _userService.getUserById(res.user!.id);
      if (appUser == null) {
        // Create a new AppUser.User based on Supabase auth user data
        appUser = AppUser.User(
          id: res.user!.id,
          name: res.user!.userMetadata?['name'] ?? 'New User',
          email: res.user!.email ?? '',
          phone: res.user!.phone ?? phoneNumber,
          password: '', // Password is not stored for OTP users
          division: '',
          district: '',
          upazila: '',
          village: '',
          createdAt: res.user!.createdAt != null
              ? DateTime.parse(res.user!.createdAt!)
              : null,
          status: 'pending', // Default status
        );
        await _userService.addUser(appUser);
      }
      return appUser;
    }
    return null;
  }

  AppUser.User? get currentUser {
    final supabaseUser = _client.auth.currentUser;
    if (supabaseUser != null) {
      // This is a simplified conversion. In a real app, you might fetch the full AppUser.User from your database.
      return AppUser.User(
        id: supabaseUser.id,
        name: supabaseUser.userMetadata?['name'] ?? 'User',
        email: supabaseUser.email ?? '',
        phone: supabaseUser.phone ?? '',
        password: '',
        division: '',
        district: '',
        upazila: '',
        village: '',
        createdAt: supabaseUser.createdAt != null
            ? DateTime.parse(supabaseUser.createdAt!)
            : null,
        status: 'pending',
      );
    }
    return null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AppUser.User?> signInWithGoogle({
    required String idToken,
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    final AuthResponse res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    if (res.user != null) {
      final UserService _userService = UserService();
      AppUser.User? appUser = await _userService.getUserById(res.user!.id);
      if (appUser == null) {
        appUser = AppUser.User(
          id: res.user!.id,
          name:
              displayName ?? res.user!.userMetadata?['full_name'] ?? 'New User',
          email: email ?? res.user!.email ?? '',
          phone: phoneNumber ?? res.user!.phone ?? '',
          password: '',
          division: '',
          district: '',
          upazila: '',
          village: '',
          createdAt: res.user!.createdAt != null
              ? DateTime.parse(res.user!.createdAt!)
              : null,
          status: 'pending',
        );
        await _userService.addUser(appUser);
      } else {
        // Update existing user with latest info from Google if needed
        appUser = appUser.copyWith(
          name: displayName ?? appUser.name,
          email: email ?? appUser.email,
          phone: phoneNumber ?? appUser.phone,
        );
        await _userService.updateUser(appUser);
      }
      return appUser;
    }
    return null;
  }
}
