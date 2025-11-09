class PackageProduct {
  final String name;
  final String quantity;
  final double unitPrice;
  final String imageUrl;

  PackageProduct({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.imageUrl,
  });

  factory PackageProduct.fromJson(Map<String, dynamic> json) {
    return PackageProduct(
      name: json['name'] ?? '',
      quantity: json['quantity']?.toString() ?? '',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'imageUrl': imageUrl,
      };
}

class Package {
  final String id;
  final String pacName;
  final String pacImageUrl;
  final double pacTotalPrice;
  final String pacDiscountString;
  final double pacDiscountPercentage;
  final double pacDiscountedPrice;
  final String pacDescription;
  final List<PackageProduct> pacProducts;

  Package({
    required this.id,
    required this.pacName,
    required this.pacImageUrl,
    required this.pacTotalPrice,
    required this.pacDiscountString,
    required this.pacDiscountPercentage,
    required this.pacDiscountedPrice,
    required this.pacDescription,
    required this.pacProducts,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    var productsFromJson = json['pacProducts'] as List<dynamic>? ?? [];
    List<PackageProduct> productList = productsFromJson
        .map((prod) => PackageProduct.fromJson(prod as Map<String, dynamic>))
        .toList();

    return Package(
      id: json['id'] ?? '',
      pacName: json['pacName'] ?? '',
      pacImageUrl: json['pacImageUrl'] ?? '',
      pacTotalPrice: (json['pacTotalPrice'] ?? 0).toDouble(),
      pacDiscountString: json['pacDiscountString'] ?? '',
      pacDiscountPercentage: (json['pacDiscountPercentage'] ?? 0).toDouble(),
      pacDiscountedPrice: (json['pacDiscountedPrice'] ?? 0).toDouble(),
      pacDescription: json['pacDescription'] ?? '',
      pacProducts: productList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pacName': pacName,
        'pacImageUrl': pacImageUrl,
        'pacTotalPrice': pacTotalPrice,
        'pacDiscountString': pacDiscountString,
        'pacDiscountPercentage': pacDiscountPercentage,
        'pacDiscountedPrice': pacDiscountedPrice,
        'pacDescription': pacDescription,
        'pacProducts': pacProducts.map((p) => p.toJson()).toList(),
      };
}
