import 'package:amar_uddokta/uddoktaa/controllers/cart_controller.dart';
import 'package:amar_uddokta/uddoktaa/controllers/favorite_controller.dart';
import 'package:flutter/material.dart';
import 'package:amar_uddokta/uddoktaa/models/cart_item.dart';
import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/uddoktaa/screens/favorite_screen.dart';
import 'package:amar_uddokta/uddoktaa/screens/zoomable_image_screen.dart';
import 'package:amar_uddokta/uddoktaa/widgets/comment_section.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.productId,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String selectedColor = '';
  String selectedSize = '';
  final CartController cartController = Get.find<CartController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final SupabaseClient _supabase =
      Supabase.instance.client; // FirebaseFirestore এর পরিবর্তে
  bool _isFavorite = false;
  bool _isLoading = false;
  int _quantity = 1;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Size-related variables
  bool _hasSizes = false;
  List<Map<String, dynamic>> _sizesData = [];
  double _selectedPrice = 0.0;
  String _selectedUnit = '';

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _initializeSizes();
  }

  void _initializeSizes() {
    final sizesData = widget.product['sizes'] as List<dynamic>?;
    if (sizesData != null && sizesData.isNotEmpty) {
      setState(() {
        _hasSizes = true;
        _sizesData = sizesData.cast<Map<String, dynamic>>();
        if (_sizesData.isNotEmpty) {
          selectedSize = _sizesData.first['size']?.toString() ?? '';
          _selectedPrice = (_sizesData.first['price'] ?? 0).toDouble();
          _selectedUnit = _sizesData.first['unit']?.toString() ?? '';
        }
      });
    } else {
      setState(() {
        _hasSizes = false;
        _selectedPrice = (widget.product['price'] ?? 0).toDouble();
        _selectedUnit = widget.product['unit'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    setState(() => _isLoading = true);
    _isFavorite = favoriteController.isFavorite(widget.productId);
    setState(() => _isLoading = false);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);

    final itemToToggle = CartItem(
      id: widget.productId,
      name: widget.product['name'] ?? 'নাম নেই',
      company: widget.product['company'] ?? 'কোম্পানি নেই',
      quantity: 1,
      price: _selectedPrice,
      unit: _selectedUnit,
      discountPercentage: (widget.product['discount'] ?? 0).toDouble(),
      imageUrl: widget.product['imageUrl'] ?? '',
      category: widget.product['category'] ?? '',
      subItemName: widget.product['subItemName'] ?? '',
      details: widget.product['details'] ?? '',
      isPackage: false,
      color: selectedColor,
      colors: _getColorsList(),
      size: selectedSize,
    );

    favoriteController.toggleFavorite(itemToToggle);
    setState(() {
      _isFavorite = favoriteController.isFavorite(widget.productId);
      _isLoading = false;
    });
  }

  List<String> _getColorsList() {
    final colorsData = widget.product['colors'];
    if (colorsData is List) {
      return colorsData.map((e) => e.toString()).toList();
    } else if (colorsData is String) {
      return colorsData.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  List<String> _getImageUrls() {
    final imagesData = widget.product['images'];
    if (imagesData is List) {
      return imagesData.map((e) => e.toString()).toList();
    } else if (imagesData is String) {
      return [imagesData];
    }
    return [widget.product['imageUrl'] ?? ''];
  }

  Future<void> _updateProductViews() async {
    try {
      final response = await _supabase
          .from('products')
          .select('views')
          .eq('id', widget.productId)
          .single();

      int currentViews = (response['views'] as int?) ?? 0;

      await _supabase.from('products').update({
        'views': currentViews + 1,
        'lastViewed': DateTime.now().toIso8601String(),
      }).eq('id', widget.productId);
    } catch (e) {
      debugPrint('ভিউ আপডেট করতে সমস্যা: $e');
    }
  }

  void _onSizeChanged(String newSize) {
    setState(() {
      selectedSize = newSize;
      // Find the price and unit for the selected size
      final sizeData = _sizesData.firstWhere(
        (size) => size['size'].toString() == newSize,
        orElse: () => _sizesData.isNotEmpty ? _sizesData.first : {},
      );
      _selectedPrice = (sizeData['price'] ?? 0).toDouble();
      _selectedUnit = sizeData['unit']?.toString() ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final name = product['name'] ?? 'নাম নেই';
    final imageUrls = _getImageUrls();
    final company = product['company'] ?? 'কোম্পানি নেই';
    final details = product['details'] ?? '';
    final discount = (product['discount'] ?? 0).toDouble();
    final category = product['category'] ?? '';
    final subItemName = product['subItemName'] ?? '';
    final colors = _getColorsList();

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateProductViews());

    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(name),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: _isLoading
                  ? const CircularProgressIndicator()
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : null,
                    ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: _buildProductDetails(
          name: name,
          imageUrls: imageUrls,
          company: company,
          details: details,
          discount: discount,
          category: category,
          subItemName: subItemName,
          colors: colors,
        ),
      ),
    );
  }

  Widget _buildProductDetails({
    required String name,
    required List<String> imageUrls,
    required String company,
    required String details,
    required double discount,
    required String category,
    required String subItemName,
    required List<String> colors,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(imageUrls, discount),
          const SizedBox(height: 16),
          _buildProductHeader(name),
          const SizedBox(height: 8),
          _buildCompanyInfo(company),
          const SizedBox(height: 8),
          _buildPriceInfo(_selectedPrice, discount),
          if (colors.isNotEmpty) _buildColorSelection(colors),
          if (_hasSizes) _buildSizeSelection(),
          _buildUnitInfo(_selectedUnit),
          _buildDetailsSection(details),
          const SizedBox(height: 16),
          _buildAddToCartButton(
            name: name,
            company: company,
            price: _selectedPrice,
            unit: _selectedUnit,
            discount: discount,
            imageUrl: imageUrls.first,
            category: category,
            subItemName: subItemName,
            details: details,
          ),
          const SizedBox(height: 24),
          CommentSection(productId: widget.productId),
        ],
      ),
    );
  }

  Widget _buildProductImage(List<String> imageUrls, double discount) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: imageUrls.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Get.to(() =>
                          ZoomableImageScreen(imageUrl: imageUrls[index]));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: Image.network(
                        imageUrls[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  );
                },
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
            ],
          ),
        ),
        if (imageUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                height: 8.0,
                width: _currentPage == index ? 24.0 : 8.0,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.red : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
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
    return StreamBuilder<Map<String, dynamic>>(
      stream: _supabase
          .from('products')
          .stream(primaryKey: ['id'])
          .eq('id', widget.productId)
          .map((event) => event.first),
      builder: (context, snapshot) {
        int views = 0;
        if (snapshot.hasData && snapshot.data != null) {
          views = snapshot.data!['views'] ?? 0;
        } else {
          views = widget.product['views'] ?? 0;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'দেখা হয়েছে: $views বার',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        );
      },
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

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('মাপ:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _sizesData.map((sizeData) {
            final sizeName = sizeData['size']?.toString() ?? '';
            final price = sizeData['price']?.toString() ?? '0';
            final unit = sizeData['unit']?.toString() ?? '';
            final isSelected = selectedSize == sizeName;

            return ChoiceChip(
              label: Text('$sizeName - ৳$price/$unit'),
              selected: isSelected,
              onSelected: (isSelected) {
                if (isSelected) {
                  _onSizeChanged(sizeName);
                }
              },
              selectedColor: Colors.green[200],
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.black54,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
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
  }) {
    return Obx(() {
      final quantity = _getQuantity();
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: quantity == 0
                  ? () {
                      final colors = _getColorsList();

                      if (colors.isNotEmpty && selectedColor.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('অনুগ্রহ করে একটি কালার সিলেক্ট করুন')),
                        );
                        return;
                      }

                      if (_hasSizes && selectedSize.isEmpty) {
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
                        id: widget.productId,
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
                      );

                      cartController.addItemToCart(itemToAdd);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('কার্টে যোগ করুন'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
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
    });
  }

  int _getQuantity() {
    final item = cartController.cartItems.firstWhereOrNull((item) =>
        item.id == widget.productId &&
        item.color == selectedColor &&
        item.size == selectedSize);
    return item?.quantity ?? 0;
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
}
