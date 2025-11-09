// File: lib/madmin/services/firestore_service.dart

import 'package:amar_uddokta/madmin/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // সব ক্যাটাগরি রিয়েল-টাইমে আনার জন্য স্ট্রিম
  Stream<List<ProductCategory>> getCategories() {
    return _supabase.from('categories').stream(primaryKey: ['id']).map((data) {
      try {
        final List<Map<String, dynamic>> jsonList =
            List<Map<String, dynamic>>.from(data);
        return jsonList.map((json) => ProductCategory.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing category data: $e');
        return <ProductCategory>[];
      }
    }).handleError((error) {
      print('Error fetching categories stream: $error');
      // এররটি আবার থ্রো করুন যাতে StreamBuilder ধরতে পারে
      throw error;
    });
  }

  // নতুন ক্যাটাগরি যোগ করা
  Future<void> addCategory(ProductCategory category) async {
    // category.toJson() এখন id এবং timestamps ছাড়া ডেটা পাঠাবে
    await _supabase.from('categories').insert(category.toJson());
  }

  // বিদ্যমান ক্যাটাগরি আপডেট করা
  Future<void> updateCategory(ProductCategory category) async {
    // category.toJson() এখন id এবং admin_updated_at সহ ডেটা পাঠাবে
    await _supabase
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id!);
  }

  // ক্যাটাগরি মুছে ফেলা
  Future<void> deleteCategory(int categoryId) async {
    await _supabase.from('categories').delete().eq('id', categoryId);
  }

  // ... আপনার অন্যান্য মেথড যেমন fetchVideoBannerData, saveUser ইত্যাদি এখানে থাকতে পারে ...
}
