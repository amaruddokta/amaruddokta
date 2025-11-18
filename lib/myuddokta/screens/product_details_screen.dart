import 'package:amar_uddokta/myuddokta/controllers/cart_controller.dart';
import 'package:amar_uddokta/myuddokta/controllers/favorite_controller.dart';
import 'package:flutter/material.dart';
import 'package:amar_uddokta/myuddokta/models/cart_item.dart';
import 'package:amar_uddokta/myuddokta/widgets/background_container.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/myuddokta/screens/zoomable_image_screen.dart';
import 'package:amar_uddokta/myuddokta/widgets/comment_section.dart';

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

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  String selectedColor = '';
  String selectedSize = '';
  final CartController cartController = Get.find<CartController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isFavorite = false;
  bool _isLoading = false;
  int _quantity = 1;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 添加浏览次数状态变量
  int _currentViews = 0;
  bool _viewsUpdated = false;

  // Size-related variables
  bool _hasSizes = false;
  List<Map<String, dynamic>> _sizesData = [];
  double _selectedPrice = 0.0;
  String _selectedUnit = '';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化浏览次数
    _currentViews = widget.product['views'] ?? 0;
    _checkIfFavorite();
    _initializeSizes();
    _initializeAnimations();
    _updateProductViews();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
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
    _fadeController.dispose();
    _slideController.dispose();
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

    // Show a nice animation when toggling favorite
    _showFavoriteAnimation();
  }

  void _showFavoriteAnimation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey,
                    size: 50,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Auto close after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
      // 获取当前浏览次数
      final response = await _supabase
          .from('products')
          .select('views')
          .eq('id', widget.productId)
          .single();

      int currentViews = (response['views'] as int?) ?? 0;

      // 更新浏览次数
      await _supabase.from('products').update({
        'views': currentViews + 1,
        'lastViewed': DateTime.now().toIso8601String(),
      }).eq('id', widget.productId);

      // 更新本地状态
      setState(() {
        _currentViews = currentViews + 1;
        _viewsUpdated = true;
      });
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

    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(name, discount),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildProductDetails(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String name, double discount) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator()
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey[600],
                  ),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProductImage(_getImageUrls(), discount),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductHeader(name),
            const SizedBox(height: 16),
            _buildCompanyInfo(company),
            const SizedBox(height: 16),
            _buildPriceInfo(_selectedPrice, discount),
            if (colors.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildColorSelection(colors),
            ],
            if (_hasSizes) ...[
              const SizedBox(height: 20),
              _buildSizeSelection(),
            ],
            const SizedBox(height: 20),
            _buildUnitInfo(_selectedUnit),
            const SizedBox(height: 20),
            _buildDetailsSection(details),
            const SizedBox(height: 30),
            _buildQuantityAndAddToCart(),
            const SizedBox(height: 30),
            CommentSection(productId: widget.productId),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(List<String> imageUrls, double discount) {
    return Stack(
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
                Get.to(() => ZoomableImageScreen(imageUrl: imageUrls[index]));
              },
              child: Hero(
                tag: 'product-image-$index',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey[200]!,
                        Colors.grey[300]!,
                      ],
                    ),
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
              ),
            );
          },
        ),
        if (discount > 0)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.red[700]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${discount.toInt()}% ছাড়',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8.0,
                  width: _currentPage == index ? 24.0 : 8.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderContent(String name, int views) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.visibility,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
          ],
        ),
      ],
    );
  }

  Widget _buildProductHeader(String name) {
    // 使用本地状态而不是StreamBuilder
    return _buildHeaderContent(name, _currentViews);
  }

  Widget _buildCompanyInfo(String company) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.business,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'কোম্পানি: $company',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(double price, double discount) {
    if (discount > 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আসল দাম: ৳${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ছাড়ের পর: ৳${(price * (100 - discount) / 100).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Text(
          'দাম: ৳${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 22,
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildColorSelection(List<String> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'রং নির্বাচন করুন:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
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
                  margin: const EdgeInsets.only(right: 12),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorValue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'মাপ নির্বাচন করুন:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: _sizesData.map((sizeData) {
            final sizeName = sizeData['size']?.toString() ?? '';
            final price = sizeData['price']?.toString() ?? '0';
            final unit = sizeData['unit']?.toString() ?? '';
            final isSelected = selectedSize == sizeName;

            return GestureDetector(
              onTap: () => _onSizeChanged(sizeName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$sizeName - ৳$price/$unit',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUnitInfo(String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.straighten,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Text(
            'একক: $unit',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
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
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            details,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityAndAddToCart() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildQuantityController(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildAddToCartButton(),
        ),
      ],
    );
  }

  Widget _buildQuantityController() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_quantity > 1) {
                  setState(() {
                    _quantity--;
                  });
                }
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomLeft: Radius.circular(30),
              ),
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                ),
                child: const Icon(
                  Icons.remove,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _quantity++;
                });
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Obx(() {
      final quantity = _getQuantity();
      return Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: MaterialButton(
          onPressed: quantity == 0
              ? () {
                  final colors = _getColorsList();

                  if (colors.isNotEmpty && selectedColor.isEmpty) {
                    _showSnackBar('অনুগ্রহ করে একটি কালার সিলেক্ট করুন');
                    return;
                  }

                  if (_hasSizes && selectedSize.isEmpty) {
                    _showSnackBar('অনুগ্রহ করে একটি সাইজ সিলেক্ট করুন');
                    return;
                  }

                  final product = widget.product;
                  final discount = (product['discount'] ?? 0).toDouble();
                  final discountedPrice = discount > 0
                      ? _selectedPrice * (100 - discount) / 100
                      : _selectedPrice;

                  final itemToAdd = CartItem(
                    id: widget.productId,
                    name: product['name'] ?? 'নাম নেই',
                    company: product['company'] ?? 'কোম্পানি নেই',
                    quantity: _quantity,
                    price: discountedPrice,
                    unit: _selectedUnit,
                    discountPercentage: discount,
                    imageUrl: _getImageUrls().first,
                    category: product['category'] ?? '',
                    subItemName: product['subItemName'] ?? '',
                    details: product['details'] ?? '',
                    isPackage: false,
                    color: selectedColor,
                    colors: _getColorsList(),
                    size: selectedSize,
                  );

                  cartController.addItemToCart(itemToAdd);
                  _showSuccessAnimation();
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'অর্ডার করুন',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Auto close after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    // Show snackbar
    _showSnackBar('কার্টে যোগ করা হয়েছে', isSuccess: true);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
