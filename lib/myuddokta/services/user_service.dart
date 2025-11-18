import 'dart:io'; // Import for File
import 'package:path/path.dart' as path; // Import for path operations
import 'package:get/get.dart'; // For firstWhereOrNull extension
import 'package:amar_uddokta/myuddokta/models/user.dart' as AppUser;
import 'package:amar_uddokta/myuddokta/services/supabase_services.dart'; // Import the shared SupabaseService
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase.instance.client

class UserService {
  final SupabaseService _supabaseService =
      SupabaseService(); // Use the shared SupabaseService

  // Fetch a single user by ID
  Future<AppUser.User?> getUserById(String userId) async {
    try {
      // SupabaseService-এর getUsers() ব্যবহার করে একটি নির্দিষ্ট ইউজার আনুন
      final users = await _supabaseService.getUsers().first;
      return users.firstWhereOrNull((user) => user.id == userId);
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Fetch all users
  Stream<List<AppUser.User>> getUsers() {
    return _supabaseService.getUsers();
  }

  // Add a new user
  Future<void> addUser(AppUser.User user) async {
    try {
      await _supabaseService.addUser(user);
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  // Update an existing user
  Future<void> updateUser(AppUser.User user) async {
    try {
      await _supabaseService.updateUser(user);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await _supabaseService.deleteUser(userId);
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Delete a user's profile image from Supabase Storage
  Future<void> deleteProfileImage(String filePath) async {
    try {
      final String bucketName =
          'profile_images'; // Assuming 'profile_images' is your bucket name
      await Supabase.instance.client.storage
          .from(bucketName)
          .remove([filePath]);
    } catch (e) {
      print('Error deleting profile image: $e');
      rethrow;
    }
  }

  // Upload a profile image to Supabase Storage
  Future<String?> uploadProfileImage(File imageFile, String userEmail) async {
    try {
      final String bucketName = 'profile_images';
      final String fileName =
          '${userEmail.replaceAll('.', '_')}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String filePath = '$userEmail/$fileName';

      final response =
          await Supabase.instance.client.storage.from(bucketName).upload(
                filePath,
                imageFile,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );

      // Get the public URL
      final String publicUrl = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } on StorageException catch (e) {
      print('Supabase Storage Error uploading profile image: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }
}
