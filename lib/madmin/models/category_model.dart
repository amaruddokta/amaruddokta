// File: lib/models/category_model.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductCategory {
  final String id;
  final String name;
  final String icon;
  final bool isActive;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.isActive = true,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Supabase ডাটাবেস থেকে প্রাপ্ত ডেটা থেকে ProductCategory অবজেক্ট তৈরি করে।
  /// ডাটাবেসের কলাম নামগুলো সাধারণত snake_case (যেমন, is_active, order_num) হয়,
  /// যা আমরা এখানে ম্যাপ করছি ডার্টের camelCase প্রপার্টিতে।
  factory ProductCategory.fromSupabase(Map<String, dynamic> data) {
    return ProductCategory(
      id: data['id'] as String,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      // ডাটাবেসে 'is_active' নামে সংরক্ষিত, তাই এভাবে পড়তে হবে
      isActive: data['is_active'] ?? true,
      // 'order' একটি SQL রিজার্ভড কীওয়ার্ড, তাই ডাটাবেসে 'order_num' ব্যবহার করা হয়েছে
      order: (data['order_num'] as num?)?.toInt() ?? 0,
      // ডাটাবেসে 'created_at' এবং 'updated_at' নামে সংরক্ষিত
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
    );
  }

  /// অবজেক্টটিকে একটি সাধারণ JSON ম্যাপে রূপান্তরিত করে।
  /// এটি সাধারণত লোকাল স্টোরেজ বা অন্য কোনো API এর জন্য ব্যবহৃত হতে পারে।
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'is_active': isActive,
      'order': order,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// অবজেক্টটিকে Supabase ডাটাবেসে পাঠানোর জন্য একটি JSON ম্যাপে রূপান্তরিত করে।
  /// এখানে ডাটাবেসের কলাম নাম (snake_case) ব্যবহার করা হয়েছে।
  Map<String, dynamic> toSupabaseJson() {
    return {
      'name': name,
      'icon': icon,
      // ডাটাবেসে 'is_active' নামে সংরক্ষণ করতে হবে
      'is_active': isActive,
      // ডাটাবেসে 'order_num' নামে সংরক্ষণ করতে হবে
      'order_num': order,
      // created_at এবং updated_at সাধারণত Supabase নিজে থেকে হ্যান্ডেল করে
      // তাই এগুলো ম্যানুয়ালি পাঠানোর প্রয়োজন নেই
    };
  }

  ProductCategory copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
