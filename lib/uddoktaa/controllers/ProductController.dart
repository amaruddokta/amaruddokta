import 'dart:io'; // File হ্যান্ডলিং এর জন্য
import 'package:get/get.dart';
import 'package:amar_uddokta/uddoktaa/services/supabase_service.dart'
    as UddoktaaSupabaseService; // Alias to avoid conflict

class ProductController extends GetxController {
  // Supabase ক্লায়েন্ট ইনিশিয়ালাইজেশন
  final UddoktaaSupabaseService.SupabaseService _supabaseService =
      UddoktaaSupabaseService.SupabaseService();
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  // সব প্রোডাক্ট ডাটাবেস থেকে আনা
  Future<void> fetchProducts() async {
    try {
      isLoading(true);
      // SupabaseService থেকে ডেটা আনা
      _supabaseService.getProducts().listen((data) {
        products.assignAll(data);
      });
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // এই মেথডগুলোর কোনো পরিবর্তন লাগেনি, কারণ এগুলো লোকাল `products` লিস্টে কাজ করে
  List<Map<String, dynamic>> getProductsByCategory(String category) {
    return products
        .where((product) => product['category'] == category)
        .toList();
  }

  Map<String, dynamic>? getProductById(String id) {
    try {
      return products.firstWhere((product) => product['id'] == id);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> searchProducts(String query) {
    return products.where((product) {
      final name = product['name'].toString().toLowerCase();
      final company = product['company'].toString().toLowerCase();
      final category = product['category'].toString().toLowerCase();
      final searchLower = query.toLowerCase();

      return name.contains(searchLower) ||
          company.contains(searchLower) ||
          category.contains(searchLower);
    }).toList();
  }

  List<Map<String, dynamic>> getSimilarProducts(
      String currentProductId, String category) {
    return products
        .where((product) =>
            product['category'] == category &&
            product['id'] != currentProductId)
        .take(5)
        .toList();
  }

  List<Map<String, dynamic>> getTopRatedProducts() {
    // লিস্টটিকে সরাসরি সর্ট করে দেয়, তাই একটি নতুন লিস্টে কপি করে নেওয়া ভালো
    final sortedProducts = List<Map<String, dynamic>>.from(products);
    sortedProducts
        .sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
    return sortedProducts;
  }

  List<Map<String, dynamic>> getDiscountedProducts() {
    return products.where((product) => (product['discount'] ?? 0) > 0).toList();
  }

  // নতুন প্রোডাক্ট ডাটাবেসে যোগ করা
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _supabaseService.addProduct(productData);
      // fetchProducts(); // Stream ব্যবহার করায় ম্যানুয়ালি রিফ্রেশ করার প্রয়োজন নেই
      Get.snackbar('Success', 'Product added successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add product: ${e.toString()}');
    }
  }

  // প্রোডাক্ট আপডেট করা
  Future<void> updateProduct(
      String id, Map<String, dynamic> updatedData) async {
    try {
      await _supabaseService.updateProduct(id, updatedData);
      // fetchProducts(); // Stream ব্যবহার করায় ম্যানুয়ালি রিফ্রেশ করার প্রয়োজন নেই
      Get.snackbar('Success', 'Product updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update product: ${e.toString()}');
    }
  }

  // প্রোডাক্ট ডিলিট করা
  Future<void> deleteProduct(String id) async {
    try {
      await _supabaseService.deleteProduct(id);
      // fetchProducts(); // Stream ব্যবহার করায় ম্যানুয়ালি রিফ্রেশ করার প্রয়োজন নেই
      Get.snackbar('Success', 'Product deleted successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete product: ${e.toString()}');
    }
  }

  // ==========================================================
  // Supabase Storage এর জন্য নতুন মেথড (ইমেজ আপলোড/ডিলিট)
  // ==========================================================

  /// একটি ফাইল (যেমন ইমেজ) Supabase Storage এ আপলোড করে এবং পাবলিক URL টি রিটার্ন করে।
  /// [file] হলো আপলোড করার জন্য ইমেজ ফাইলটি।
  /// [productId] হলো প্রোডাক্টের আইডি, যা ফাইলের পাথ ইউনিক রাখতে সাহায্য করবে।
  Future<String?> uploadProductImage(File file, String productId) async {
    try {
      return await _supabaseService.uploadProductImage(file, productId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: ${e.toString()}');
      return null;
    }
  }

  /// Supabase Storage থেকে একটি ইমেজ ডিলিট করে।
  /// [imageUrl] হলো সেই ইমেজের পাবলিক URL, যার থেকে ফাইলের পাথ বের করা হবে।
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      await _supabaseService.deleteProductImage(imageUrl);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete image: ${e.toString()}');
    }
  }
}
