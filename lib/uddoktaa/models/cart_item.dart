class CartItem {
  final String id;
  final String name;
  final String company;
  int quantity;
  final double price;
  final String unit;
  final double discountPercentage;
  final String imageUrl;
  final String category;
  final String subItemName;
  final String details;
  final bool isPackage;
  final String? color;
  final List<String>? colors;
  final String? size;
  final int? stock; // Added stock field
  final double? weightInKg;

  CartItem({
    required this.id,
    required this.name,
    required this.company,
    required this.quantity,
    required this.price,
    required this.unit,
    required this.discountPercentage,
    required this.imageUrl,
    required this.category,
    required this.subItemName,
    required this.details,
    required this.isPackage,
    this.color,
    this.colors,
    this.size,
    this.stock, // Added stock to constructor
    this.weightInKg,
  });

  /// ডিসকাউন্ট শেষে একক পণ্যের দাম
  double get discountedPrice => price * (100 - discountPercentage) / 100;

  /// মোট দাম (discount সহ)
  double get totalPrice => discountedPrice * quantity;

  /// JSON এ রূপান্তর
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'quantity': quantity,
      'price': price,
      'unit': unit,
      'discountPercentage': discountPercentage,
      'imageUrl': imageUrl,
      'category': category,
      'subItemName': subItemName,
      'details': details,
      'isPackage': isPackage,
      'color': color,
      'colors': colors,
      'size': size,
      'stock': stock, // Added stock to toMap
      'weightInKg': weightInKg,
      'discountedPrice': discountedPrice,
      'total': totalPrice,
    };
  }

  /// JSON থেকে CartItem তৈরি
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      company: json['company'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      subItemName: json['subItemName'] ?? '',
      details: json['details'] ?? '',
      isPackage: json['isPackage'] ?? false,
      color: json['color'],
      colors: json['colors'] != null ? List<String>.from(json['colors']) : null,
      size: json['size'],
      stock: json['stock'], // Added stock to fromJson
      weightInKg: (json['weightInKg'] ?? 0.0).toDouble(),
    );
  }

  CartItem copyWith({
    String? id,
    String? name,
    String? company,
    int? quantity,
    double? price,
    String? unit,
    double? discountPercentage,
    String? imageUrl,
    String? category,
    String? subItemName,
    String? details,
    bool? isPackage,
    String? color,
    List<String>? colors,
    String? size,
    int? stock, // Added stock to copyWith
    double? weightInKg,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      subItemName: subItemName ?? this.subItemName,
      details: details ?? this.details,
      isPackage: isPackage ?? this.isPackage,
      color: color ?? this.color,
      colors: colors ?? this.colors,
      size: size ?? this.size,
      stock: stock ?? this.stock, // Added stock to copyWith
      weightInKg: weightInKg ?? this.weightInKg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          color == other.color &&
          size == other.size;

  @override
  int get hashCode => id.hashCode ^ color.hashCode ^ size.hashCode;
}
