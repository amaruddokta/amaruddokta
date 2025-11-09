import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading(true);
      final List<Map<String, dynamic>> response =
          await _supabase.from('products').select();

      products.assignAll(response.map((data) {
        return {
          'id': data['id'],
          ...data,
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'reviewCount': data['reviewCount'] ?? 0,
        };
      }).toList());
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch products: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

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
    return products
      ..sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
  }

  List<Map<String, dynamic>> getDiscountedProducts() {
    return products.where((product) => (product['discount'] ?? 0) > 0).toList();
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _supabase.from('products').insert(productData);
      await fetchProducts();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add product: ${e.toString()}');
    }
  }

  Future<void> updateProduct(
      String id, Map<String, dynamic> updatedData) async {
    try {
      await _supabase.from('products').update(updatedData).eq('id', id);
      await fetchProducts();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update product: ${e.toString()}');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
      await fetchProducts();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete product: ${e.toString()}');
    }
  }
}
