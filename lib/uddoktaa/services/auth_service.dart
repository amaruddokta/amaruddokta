import 'package:flutter/foundation.dart';
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
      final UserService userService = UserService();
      // Check if user exists in our 'users' table, if not, create one
      AppUser.User? appUser = await userService.getUserById(res.user!.id);
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
          createdAt: DateTime.parse(res.user!.createdAt),
          status: 'pending', // Default status
        );
        await userService.addUser(appUser);
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
        createdAt: DateTime.parse(supabaseUser.createdAt),
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
    try {
      debugPrint("Signing in to Supabase with Google ID token...");

      final AuthResponse res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      if (res.user == null) {
        debugPrint("Failed to get user from Supabase after Google sign-in");
        throw Exception("Failed to authenticate with Supabase");
      }

      debugPrint(
          "Successfully authenticated with Supabase. User ID: ${res.user!.id}");

      final UserService userService = UserService();
      AppUser.User? appUser = await userService.getUserById(res.user!.id);

      if (appUser == null) {
        debugPrint("Creating new user in database...");
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
          createdAt: DateTime.parse(res.user!.createdAt),
          status: 'pending',
        );

        try {
          await userService.addUser(appUser);
          debugPrint("Successfully created new user in database");
        } catch (e) {
          debugPrint("Failed to create user in database: $e");
          throw Exception("Failed to create user in database: $e");
        }
      } else {
        debugPrint("Updating existing user in database...");
        // Update existing user with latest info from Google if needed
        appUser = appUser.copyWith(
          name: displayName ?? appUser.name,
          email: email ?? appUser.email,
          phone: phoneNumber ?? appUser.phone,
        );

        try {
          await userService.updateUser(appUser);
          debugPrint("Successfully updated user in database");
        } catch (e) {
          debugPrint("Failed to update user in database: $e");
          // Don't throw here, as the user is already authenticated
        }
      }
      return appUser;
    } on AuthException catch (e) {
      debugPrint("Supabase AuthException: ${e.message}");
      throw Exception("Authentication failed: ${e.message}");
    } catch (e) {
      debugPrint("Unexpected error during Google sign-in: $e");
      throw Exception("Unexpected error: $e");
    }
  }
}
