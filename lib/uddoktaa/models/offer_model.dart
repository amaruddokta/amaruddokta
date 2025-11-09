class Offer {
  final String id;
  final String name;
  final String details;
  final String imageUrl;
  final String company;
  final double originalPrice;
  final String unit;
  final double discountPercentage;
  final int stock;
  final List<String> colors;
  final List<String> size;
  final String category;
  final String subItemName;
  final bool isActive;
  final DateTime endTime;

  Offer({
    required this.id,
    required this.name,
    required this.details,
    required this.imageUrl,
    required this.company,
    required this.originalPrice,
    required this.unit,
    required this.discountPercentage,
    required this.stock,
    required this.colors,
    required this.size,
    required this.category,
    required this.subItemName,
    required this.isActive,
    required this.endTime,
  });

  factory Offer.fromSupabase(Map<String, dynamic> data) {
    return Offer(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      details: data['details'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      company: data['company'] ?? '',
      originalPrice: (data['originalPrice'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      colors: List<String>.from(data['colors'] ?? []),
      size: List<String>.from(data['size'] ?? []),
      category: data['category'] ?? '',
      subItemName: data['subItemName'] ?? '',
      isActive: data['isActive'] ?? false,
      endTime: DateTime.parse(data['endTime']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'details': details,
      'imageUrl': imageUrl,
      'company': company,
      'originalPrice': originalPrice,
      'unit': unit,
      'discountPercentage': discountPercentage,
      'stock': stock,
      'colors': colors,
      'size': size,
      'category': category,
      'subItemName': subItemName,
      'isActive': isActive,
      'endTime': endTime.toIso8601String(),
    };
  }
}
