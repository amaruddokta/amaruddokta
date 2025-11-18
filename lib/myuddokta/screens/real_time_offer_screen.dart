import 'package:amar_uddokta/myuddokta/controllers/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:amar_uddokta/myuddokta/models/cart_item.dart';
import 'package:amar_uddokta/myuddokta/widgets/background_container.dart';
import 'package:get/get.dart';

class RealTimeOfferScreen extends StatefulWidget {
  final Map<String, dynamic> offer;

  const RealTimeOfferScreen({super.key, required this.offer});

  @override
  _RealTimeOfferScreenState createState() => _RealTimeOfferScreenState();
}

class _RealTimeOfferScreenState extends State<RealTimeOfferScreen> {
  String selectedColor = '';
  String selectedSize = '';
  int _quantity = 1;
  final CartController cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();
  }

  List<String> _getColorsList() {
    final colorsData = widget.offer['colors'];
    if (colorsData is List) {
      return colorsData.map((e) => e.toString()).toList();
    } else if (colorsData is String) {
      return colorsData.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  List<String> _getSizesList() {
    final sizesData = widget.offer['size'];
    print('Sizes data: $sizesData');
    if (sizesData is List) {
      return sizesData.map((e) => e.toString()).toList();
    } else if (sizesData is String) {
      return sizesData
          .split(',')
          .map((e) => e.trim().replaceAll('"', ''))
          .toList();
    }
    return [];
  }

  Color _getColorFromName(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'black': Colors.black,
      'white': Colors.white,
      'yellow': Colors.yellow,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'pink': Colors.pink,
      'brown': Colors.brown,
      'grey': Colors.grey,
    };
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.offer['name'] ?? 'Unknown';
    final imageUrl = widget.offer['imageUrl'] ?? '';
    final company = widget.offer['company'] ?? 'Unknown';
    final price = (widget.offer['originalPrice'] ?? 0).toDouble();
    final unit = widget.offer['unit'] ?? '';
    final details = widget.offer['details'] ?? '';
    final discount = (widget.offer['discountPercentage'] ?? 0).toDouble();
    final stock = (widget.offer['stock'] ?? 0).toInt();
    final colors = _getColorsList();
    final sizes = _getSizesList();
    final category = widget.offer['category'] ?? '';
    final subItemName = widget.offer['subItemName'] ?? '';

    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(name),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildOfferDetails(
          name: name,
          imageUrl: imageUrl,
          company: company,
          price: price,
          unit: unit,
          details: details,
          discount: discount,
          stock: stock,
          colors: colors,
          sizes: sizes,
          category: category,
          subItemName: subItemName,
        ),
      ),
    );
  }

  Widget _buildOfferDetails({
    required String name,
    required String imageUrl,
    required String company,
    required double price,
    required String unit,
    required String details,
    required double discount,
    required int stock,
    required List<String> colors,
    required List<String> sizes,
    required String category,
    required String subItemName,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(imageUrl, discount, stock),
          const SizedBox(height: 16),
          _buildProductHeader(name),
          const SizedBox(height: 8),
          _buildCompanyInfo(company),
          const SizedBox(height: 8),
          _buildPriceInfo(price, discount),
          if (colors.isNotEmpty) _buildColorSelection(colors),
          if (sizes.isNotEmpty) _buildSizeSelection(sizes),
          _buildUnitInfo(unit),
          _buildDetailsSection(details),
          const SizedBox(height: 16),
          _buildAddToCartButton(
            name: name,
            company: company,
            price: price,
            unit: unit,
            discount: discount,
            imageUrl: imageUrl,
            category: category,
            subItemName: subItemName,
            details: details,
            stock: stock,
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, double discount, int stock) {
    return Stack(
      children: [
        Image.network(
          imageUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 250,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 50),
          ),
        ),
        if (discount > 0)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${discount.toInt()}% ছাড়',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (stock == 0)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Text(
                  'স্টক শেষ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: _buildQuantityController(),
        ),
      ],
    );
  }

  Widget _buildProductHeader(String name) {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCompanyInfo(String company) {
    return Text(
      'কোম্পানি: $company',
      style: const TextStyle(fontSize: 18),
    );
  }

  Widget _buildPriceInfo(double price, double discount) {
    if (discount > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আসল দাম: ৳${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
          Text(
            'ছাড়ের পর: ৳${(price * (100 - discount) / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      return Text(
        'দাম: ৳${price.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 18),
      );
    }
  }

  Widget _buildColorSelection(List<String> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('রং:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final colorName = colors[index];
              final colorValue = _getColorFromName(colorName);
              final isSelected = selectedColor == colorName;

              return GestureDetector(
                onTap: () => setState(() => selectedColor = colorName),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSizeSelection(List<String> sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('মাপ:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: sizes.map((sizeName) {
            return ChoiceChip(
              label: Text(sizeName),
              selected: selectedSize == sizeName,
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    selectedSize = sizeName;
                  });
                }
              },
              selectedColor: Colors.green[200],
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: selectedSize == sizeName ? Colors.black : Colors.black54,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUnitInfo(String unit) {
    return Text(
      'একক: $unit',
      style: const TextStyle(fontSize: 18),
    );
  }

  Widget _buildDetailsSection(String details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'বিস্তারিত:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          details,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildQuantityController() {
    return Container(
      height: 50,
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: Color.fromARGB(255, 223, 10, 10)),
            onPressed: () {
              if (_quantity > 1) {
                setState(() {
                  _quantity--;
                });
              }
            },
          ),
          Text('$_quantity',
              style: const TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 224, 8, 8),
                  fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color.fromARGB(255, 237, 6, 6)),
            onPressed: () {
              setState(() {
                _quantity++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton({
    required String name,
    required String company,
    required double price,
    required String unit,
    required double discount,
    required String imageUrl,
    required String category,
    required String subItemName,
    required String details,
    required int stock,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: stock == 0
                ? null
                : () {
                    final colors = _getColorsList();
                    final sizes = _getSizesList();

                    if (colors.isNotEmpty && selectedColor.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('অনুগ্রহ করে একটি কালার সিলেক্ট করুন')),
                      );
                      return;
                    }

                    if (sizes.isNotEmpty && selectedSize.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('অনুগ্রহ করে একটি সাইজ সিলেক্ট করুন')),
                      );
                      return;
                    }

                    final discountedPrice =
                        discount > 0 ? price * (100 - discount) / 100 : price;

                    final itemToAdd = CartItem(
                      id: widget.offer['id'] ?? name,
                      name: name,
                      company: company,
                      quantity: _quantity,
                      price: discountedPrice,
                      unit: unit,
                      discountPercentage: discount,
                      imageUrl: imageUrl,
                      category: category,
                      subItemName: subItemName,
                      details: details,
                      isPackage: false,
                      color: selectedColor,
                      colors: _getColorsList(),
                      size: selectedSize,
                      stock: stock,
                    );

                    cartController.addItemToCart(itemToAdd);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('কার্টে যুক্ত হয়েছে'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.green,
            ),
            child: const Text('কার্টে যোগ করুন'),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => Get.toNamed('/cart'),
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(50, 50),
          ),
        ),
      ],
    );
  }
}
