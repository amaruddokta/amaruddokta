import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    client = Supabase.instance.client;
  }

  // Product operations
  Stream<List<Map<String, dynamic>>> getProducts() {
    return client.from('products').stream(primaryKey: ['id']);
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    await client.from('products').insert(productData);
  }

  Future<void> updateProduct(
      String id, Map<String, dynamic> updatedData) async {
    await client.from('products').update(updatedData).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  // Supabase Storage operations for product images
  Future<String?> uploadProductImage(File file, String productId) async {
    try {
      final String bucketName = 'product-images';
      final String filePath =
          '$productId/${DateTime.now().millisecondsSinceEpoch}';

      await client.storage.from(bucketName).upload(filePath, file);

      final String publicUrl =
          client.storage.from(bucketName).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final String bucketName = 'product-images';
      final Uri uri = Uri.parse(imageUrl);
      final String filePath = uri.pathSegments.last;

      await client.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      rethrow;
    }
  }
}
