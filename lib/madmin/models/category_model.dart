// File: lib/models/category_model.dart

class ProductCategory {
  final int? id;
  final String categoriesName;
  final String categoriesIcon;
  final bool isActive;
  final int order;
  final DateTime? adminCreatedAt;
  final DateTime? adminUpdatedAt;

  ProductCategory({
    this.id, // নতুন ক্যাটাগরির জন্য id হবে null
    required this.categoriesName,
    required this.categoriesIcon,
    this.isActive = true,
    this.order = 0,
    this.adminCreatedAt,
    this.adminUpdatedAt,
  });

  // Supabase থেকে আসা JSON ডেটাকে Dart অবজেক্টে রূপান্তর করে
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int?,
      categoriesName: json['categories_name'] as String? ?? '',
      categoriesIcon: json['categories_icon'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      adminCreatedAt: json['admin_created_at'] != null
          ? DateTime.parse(json['admin_created_at'])
          : null,
      adminUpdatedAt: json['admin_updated_at'] != null
          ? DateTime.parse(json['admin_updated_at'])
          : null,
    );
  }

  // Dart অবজেক্টকে Supabase এর জন্য JSON ডেটায় রূপান্তর করে
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'categories_name': categoriesName,
      'categories_icon': categoriesIcon,
      'is_active': isActive,
      'order': order,
    };

    // যদি id থাকে, তাহলে এটি একটি আপডেট অপারেশন।
    // আমরা id পাঠাব রো-টি আইডেন্টিফাই করার জন্য এবং admin_updated_at আপডেট করার জন্য।
    if (id != null) {
      data['id'] = id;
      data['admin_updated_at'] = DateTime.now().toIso8601String();
    }
    // যদি id না থাকে (অর্থাৎ নতুন রেকর্ড), আমরা শুধু উপরের ডেটাগুলো পাঠাব।
    // Supabase স্বয়ংক্রিয়ভাবে id, admin_created_at এবং admin_updated_at তৈরি করবে।

    return data;
  }

  // একটি অবজেক্টের কিছু ফিল্ড আপডেট করে নতুন অবজেক্ট তৈরি করতে ব্যবহৃত হয়
  ProductCategory copyWith({
    int? id,
    String? categoriesName,
    String? categoriesIcon,
    bool? isActive,
    int? order,
    DateTime? adminCreatedAt,
    DateTime? adminUpdatedAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      categoriesName: categoriesName ?? this.categoriesName,
      categoriesIcon: categoriesIcon ?? this.categoriesIcon,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      adminCreatedAt: adminCreatedAt ?? this.adminCreatedAt,
      adminUpdatedAt: adminUpdatedAt ?? this.adminUpdatedAt,
    );
  }
}