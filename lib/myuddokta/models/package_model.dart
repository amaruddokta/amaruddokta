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
  final String name;
  final String imageUrl;
  final double totalPrice;
  final String discountString;
  final double discountPercentage;
  final double discountedPrice;
  final String description;
  final List<PackageProduct> products;

  Package({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.totalPrice,
    required this.discountString,
    required this.discountPercentage,
    required this.discountedPrice,
    required this.description,
    required this.products,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    var productsFromJson = json['products'] as List<dynamic>? ?? [];
    List<PackageProduct> productList = productsFromJson
        .map((prod) => PackageProduct.fromJson(prod as Map<String, dynamic>))
        .toList();

    return Package(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      discountString: json['discountString'] ?? '',
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      discountedPrice: (json['discountedPrice'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      products: productList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'totalPrice': totalPrice,
        'discountString': discountString,
        'discountPercentage': discountPercentage,
        'discountedPrice': discountedPrice,
        'description': description,
        'products': products.map((p) => p.toJson()).toList(),
      };
}
