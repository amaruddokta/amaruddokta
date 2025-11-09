class ProductCategory {
  final int? id;
  final String categoriesName;
  final String categoriesIcon;
  final bool isActive;
  final int order;
  final DateTime? adminCreatedAt;
  final DateTime? adminUpdatedAt;

  ProductCategory({
    this.id,
    required this.categoriesName,
    required this.categoriesIcon,
    this.isActive = true,
    this.order = 0,
    this.adminCreatedAt,
    this.adminUpdatedAt,
  });

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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // id শুধুমাত্র আপডেটের সময় প্রয়োজন, নতুন রেকর্ডের জন্য নয়
    if (id != null) {
      data['id'] = id;
    }

    data['categories_name'] = categoriesName;
    data['categories_icon'] = categoriesIcon;
    data['is_active'] = isActive;
    data['order'] = order;

    // নতুন রেকর্ডের জন্য, সুপাবেস স্বয়ংক্রিয়ভাবে টাইমস্ট্যাম্প সেট করবে
    // আপডেটের জন্য, আমরা শুধু admin_updated_at পাস করব
    if (adminCreatedAt != null) {
      data['admin_created_at'] = adminCreatedAt!.toIso8601String();
    }

    if (adminUpdatedAt != null) {
      data['admin_updated_at'] = adminUpdatedAt!.toIso8601String();
    }

    return data;
  }

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
