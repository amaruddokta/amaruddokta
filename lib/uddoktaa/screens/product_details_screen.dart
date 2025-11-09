import 'package:amar_uddokta/uddoktaa/controllers/cart_controller.dart';
import 'package:amar_uddokta/uddoktaa/controllers/favorite_controller.dart';
import 'package:flutter/material.dart';
import 'package:amar_uddokta/uddoktaa/models/cart_item.dart';
import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  double _currentPrice = 0.0;
  String _currentUnit = '';
  Map<String, dynamic>? _selectedSizeData;

  final CartController cartController = Get.find<CartController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isFavorite = false;
  bool _isLoading = false;
  int _quantity = 1;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _initializePriceAndUnit();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateProductViews());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializePriceAndUnit() {
    final List<dynamic>? sizesData = widget.product['sizes'] as List<dynamic>?;
    if (sizesData != null && sizesData.isNotEmpty) {
      final firstSizeEntry = sizesData.first as Map<String, dynamic>;
      _currentPrice = (firstSizeEntry['price'] ?? 0).toDouble();
      _currentUnit =
          firstSizeEntry['unit']?.toString() ?? ''; // Ensure unit is a string
      selectedSize = firstSizeEntry['size']?.toString() ?? '';
      _selectedSizeData = firstSizeEntry;
    } else {
      _currentPrice = (widget.product['price'] ?? 0).toDouble();
      _currentUnit = widget.product['unit'] ?? '';
    }
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
      name: widget.product['usernames'] ?? 'নাম নেই',
      company: widget.product['userscompanys'] ?? 'কোম্পানি নেই',
      quantity: 1,
      price: _currentPrice,
      unit: _currentUnit,
      discountPercentage: (widget.product['userdiscounts'] ?? 0).toDouble(),
      imageUrl: widget.product['userimageUrls'] ?? '',
      category: widget.product['UCategorys'] ?? '',
      subItemName: widget.product['userItem'] ?? '',
      details: widget.product['userdetailss'] ?? '',
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
    final colorsData = widget.product['usercolors'];
    if (colorsData is List) {
      return colorsData.map((e) => e.toString()).toList();
    } else if (colorsData is String) {
      return colorsData.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _getSizesWithDetails() {
    final sizesData = widget.product['sizes'];
    if (sizesData is List) {
      return sizesData.map((e) => e as Map<String, dynamic>).toList();
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
    // Ensure userimageUrls is always a string, even if it's an int
    return [widget.product['userimageUrls']?.toString() ?? ''];
  }

  Future<void> _updateProductViews() async {
    try {
      final response = await _supabase
          .from('ponno')
          .select('views')
          .eq('id', widget.productId)
          .single();

      int currentViews = (response['views'] as int?) ?? 0;
      int newViews = currentViews + 1;

      await _supabase.from('ponno').update({
        'views': newViews,
        'lastViewed': DateTime.now().toIso8601String(),
      }).eq('id', widget.productId);
    } catch (e) {
      debugPrint('ভিউ আপডেট করতে সমস্যা: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final name = product['usernames'] ?? 'নাম নেই';
    final imageUrls = _getImageUrls();
    final company = product['userscompanys'] ?? 'কোম্পানি নেই';
    final discount = (product['userdiscounts'] ?? 0).toDouble();
    final category = product['UCategorys'] ?? '';
    final subItemName = product['userItem'] ?? '';
    final colors = _getColorsList();
    final sizes = _getSizesWithDetails();

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
          price: _currentPrice,
          unit: _currentUnit,
          details: product['userdetailss']?.toString() ??
              '', // Ensure details is a string
          discount: discount,
          category: category,
          subItemName: subItemName,
          colors: colors,
          sizes: sizes,
        ),
      ),
    );
  }

  Widget _buildProductDetails({
    required String name,
    required List<String> imageUrls,
    required String company,
    required double price,
    required String unit,
    required String details,
    required double discount,
    required String category,
    required String subItemName,
    required List<String> colors,
    required List<Map<String, dynamic>> sizes,
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
            imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
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
    if (imageUrls.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    }
    final imageUrl = imageUrls.first;
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Get.to(() => ZoomableImageScreen(imageUrl: imageUrl)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
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
        ],
      ),
    );
  }

  Widget _buildProductHeader(String name) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('ponno')
          .stream(primaryKey: ['id']).eq('id', widget.productId),
      builder: (context, snapshot) {
        int views = 0;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          views = (snapshot.data!.first['views'] as int?) ?? 0;
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

  Widget _buildSizeSelection(List<Map<String, dynamic>> sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('মাপ:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: sizes.map((sizeEntry) {
            final sizeName = sizeEntry['size']?.toString() ?? '';
            final isSelected = selectedSize == sizeName;

            return ChoiceChip(
              label: Text(sizeName),
              selected: isSelected,
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    selectedSize = sizeName;
                    _selectedSizeData = sizeEntry;
                    _currentPrice = (sizeEntry['price'] ?? 0).toDouble();
                    _currentUnit = sizeEntry['unit']?.toString() ??
                        ''; // Ensure unit is a string
                  });
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
                      final sizes = _getSizesWithDetails();

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

                      final itemToAdd = CartItem(
                        id: widget.productId,
                        name: name,
                        company: company,
                        quantity: _quantity,
                        price: _currentPrice,
                        unit: _currentUnit,
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
                          content: Text('কার্টে যুক্ত হয়েছে'),
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
