import 'package:supabase_flutter/supabase_flutter.dart';

class SubItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl; // Added imageUrl field
  final bool isActive;
  final int order;
  final String? createdAt;
  final String? updatedAt;

  SubItem({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '', // Initialize imageUrl
    this.isActive = true,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory SubItem.fromMap(Map<String, dynamic> data) {
    return SubItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '', // Retrieve imageUrl from Supabase
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: data['createdAt'] as String?,
      updatedAt: data['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl, // Add imageUrl to Supabase map
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  SubItem copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl, // Added imageUrl to copyWith
    bool? isActive,
    int? order,
    String? createdAt,
    String? updatedAt,
  }) {
    return SubItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl, // Update imageUrl in copyWith
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
