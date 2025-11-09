import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageHelper {
  static Future<String> uploadImage(File image) async {
    try {
      final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('products')
          .upload(fileName, image);
      return Supabase.instance.client.storage
          .from('products')
          .getPublicUrl(fileName);
    } catch (e) {
      print("Upload failed: $e");
      rethrow;
    }
  }
}
