import 'package:amar_uddokta/myuddokta/screens/product_details_screen.dart';
import 'package:amar_uddokta/myuddokta/widgets/background_container.dart';
import 'package:amar_uddokta/myuddokta/controllers/favorite_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/myuddokta/controllers/cart_controller.dart';
import 'package:amar_uddokta/myuddokta/models/cart_item.dart';
import 'package:shimmer/shimmer.dart';

class SubItemScreen extends StatefulWidget {
  final String categoryName;
  final String searchQuery;

  const SubItemScreen({
    super.key,
    required this.categoryName,
    this.searchQuery = '',
  });

  @override
  State<SubItemScreen> createState() => _SubItemScreenState();
}

class _SubItemScreenState extends State<SubItemScreen>
    with TickerProviderStateMixin {
  final CartController _cartController = Get.find<CartController>();
  final FavoriteController _favoriteController = Get.find<FavoriteController>();
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, int> quantities = {};
  late Future<List<Map<String, dynamic>>> _futureProducts;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = false;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetchProducts();
    _setupCartListener();
    _setupAnimation();
    _setupScrollListener();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isExpanded = _scrollController.offset > 100;
        if (isExpanded != _isAppBarExpanded) {
          setState(() {
            _isAppBarExpanded = isExpanded;
          });
        }
      }
    });
  }

  void _setupCartListener() {
    _cartController.cartItems.listen((cartItems) {
      if (mounted) {
        final newQuantities = <String, int>{};
        for (var item in cartItems) {
          newQuantities.update(item.id, (value) => value + item.quantity,
              ifAbsent: () => item.quantity);
        }
        setState(() {
          quantities = newQuantities;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SubItemScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.categoryName != widget.categoryName) {
      _futureProducts = _fetchProducts();
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final response = await _supabase.from('products').select();

      final allProducts = List<Map<String, dynamic>>.from(response as List);

      // ফিল্টারিং লজিক
      final filteredProducts = allProducts.where((product) {
        final matchesCategory = widget.categoryName.isEmpty ||
            (product['category'] ?? '').toString().trim() ==
                widget.categoryName.trim();

        final matchesSearch = (product['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(widget.searchQuery.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();

      return filteredProducts;
    } on PostgrestException catch (e) {
      debugPrint('পণ্য লোড করতে সমস্যা: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _futureProducts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerEffect();
                    } else if (snapshot.hasError) {
                      return _buildErrorWidget(snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyWidget();
                    }

                    return _buildProductList(snapshot.data!);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _isAppBarExpanded
          ? Theme.of(context).primaryColor.withOpacity(0.9)
          : Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(
            color: _isAppBarExpanded ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.7),
                Theme.of(context).primaryColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _buildShimmerHeader(),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerHeader() {
    return Container(
      height: 30,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'ত্রুটি: $error',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _futureProducts = _fetchProducts();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('পুনরায় চেষ্টা করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'কোনো প্রোডাক্ট পাওয়া যায়নি',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'অন্য ক্যাটাগরি বা সার্চ টার্ম চেষ্টা করুন',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> products) {
    final groupedProducts = _groupProductsBySubItem(products);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: groupedProducts.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubItemHeader(entry.key),
              _buildProductsGrid(entry.value),
            ],
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupProductsBySubItem(
      List<Map<String, dynamic>> products) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var product in products) {
      final subItem = (product['subItemName'] ?? 'Others').toString();
      grouped.putIfAbsent(subItem, () => []).add(product);
    }
    return grouped;
  }

  Widget _buildSubItemHeader(String subItemName) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        subItemName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<Map<String, dynamic>> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(5),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  0.1 + (index * 0.05),
                  0.5 + (index * 0.05),
                  curve: Curves.easeOut,
                ),
              ),
            );
            return Transform.scale(
              scale: animation.value,
              child: Opacity(
                opacity: animation.value,
                child: _buildProductCard(products[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Unknown';
    double displayPrice = (product['price'] ?? 0).toDouble();
    String displayUnit = product['unit'] ?? '';
    final discount = (product['discount'] ?? 0).toDouble();
    final imageUrl = product['imageUrl'] ?? '';
    final company = product['company'] ?? 'Unknown';
    final details = product['details'] ?? '';
    final stock = (product['stock'] ?? 0).toInt();
    final subItemName = (product['subItemName'] ?? 'Others').toString();
    final productId = product['id'] ?? name;
    final category = product['category'] ?? widget.categoryName;

    final colors = _getColorsList(product['colors']);
    final qty = quantities[product['id'] ?? name] ?? 0;

    // Handle sizes data
    final List<dynamic>? sizesData = product['sizes'] as List<dynamic>?;
    if (sizesData != null && sizesData.isNotEmpty) {
      final firstSizeDetails = _getFirstSizePriceUnit(sizesData);
      if (firstSizeDetails.isNotEmpty) {
        displayPrice = (firstSizeDetails['price'] ?? 0).toDouble();
        displayUnit = firstSizeDetails['unit'] ?? '';
      }
    }

    final discountedPrice =
        (displayPrice * (100 - discount) / 100).toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProductImage(
              imageUrl,
              discount,
              stock,
              productId,
              name,
              colors,
              company,
              displayPrice,
              displayUnit,
              category,
              subItemName,
              details,
              qty,
              product,
            ),
            // Reduced height and removed space between
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '৳$discountedPrice',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (discount > 0)
                        Expanded(
                          child: Text(
                            '৳${displayPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8), // Reduced space here
                  _buildOrderButton(
                    product: product,
                    productId: productId,
                    name: name,
                    company: company,
                    price: displayPrice,
                    unit: displayUnit,
                    discount: discount,
                    imageUrl: imageUrl,
                    category: category,
                    subItemName: subItemName,
                    details: details,
                    colors: colors,
                    stock: stock,
                    qty: qty,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getFirstSizePriceUnit(List<dynamic>? sizesData) {
    if (sizesData == null || sizesData.isEmpty) {
      return {};
    }
    return sizesData.first as Map<String, dynamic>;
  }

  Widget _buildProductImage(
    String imageUrl,
    double discount,
    int stock,
    String productId,
    String name,
    List<String>? colors,
    String company,
    double price,
    String unit,
    String category,
    String subItemName,
    String details,
    int qty,
    Map<String, dynamic> product,
  ) {
    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _navigateToProductDetails(product),
            child: Container(
              width: double.infinity,
              height: double.infinity,
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
              child: Hero(
                tag: 'product-$productId',
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (discount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '-${discount.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(
                () => IconButton(
                  icon: Icon(
                    _favoriteController.isFavorite(productId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favoriteController.isFavorite(productId)
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                  onPressed: () => _toggleFavorite(
                    productId: productId,
                    name: name,
                    company: company,
                    price: price,
                    unit: unit,
                    discount: discount,
                    imageUrl: imageUrl,
                    category: category,
                    subItemName: subItemName,
                    details: details,
                    colors: colors,
                    qty: qty,
                  ),
                ),
              ),
            ),
          ),
          if (stock == 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'স্টক শেষ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderButton({
    required Map<String, dynamic> product,
    required String productId,
    required String name,
    required String company,
    required double price,
    required String unit,
    required double discount,
    required String imageUrl,
    required String category,
    required String subItemName,
    required String details,
    required List<String>? colors,
    required int stock,
    required int qty,
  }) {
    return stock == 0
        ? Container(
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'স্টক নেই',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          )
        : qty == 0
            ? Container(
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: MaterialButton(
                  onPressed: () {
                    final colorsData = product['colors'];
                    final sizesData = product['sizes'];

                    final bool hasColors = colorsData != null &&
                        (colorsData is List
                            ? colorsData.isNotEmpty
                            : (colorsData as String).isNotEmpty);
                    final bool hasSizes = sizesData != null &&
                        (sizesData is List
                            ? sizesData.isNotEmpty
                            : (sizesData as String).isNotEmpty);

                    if (hasColors || hasSizes) {
                      _navigateToProductDetails(product);
                    } else {
                      _addToCart(
                        productId: productId,
                        name: name,
                        company: company,
                        price: price,
                        unit: unit,
                        discount: discount,
                        imageUrl: imageUrl,
                        category: category,
                        subItemName: subItemName,
                        details: details,
                        colors: colors,
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'অর্ডার করুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).primaryColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _cartController.decreaseQuantity(productId,
                              color: null, size: null);
                        },
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                          child: const Icon(
                            Icons.remove,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$qty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _cartController.increaseQuantity(productId,
                              color: null, size: null);
                        },
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
  }

  List<String>? _getColorsList(dynamic colorsData) {
    if (colorsData is List) {
      return colorsData.map((e) => e.toString()).toList();
    } else if (colorsData is String) {
      return colorsData.split(',').map((e) => e.trim()).toList();
    }
    return null;
  }

  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailsScreen(
          product: product,
          productId: product['id'] ?? '',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _toggleFavorite({
    required String productId,
    required String name,
    required String company,
    required double price,
    required String unit,
    required double discount,
    required String imageUrl,
    required String category,
    required String subItemName,
    required String details,
    required List<String>? colors,
    required int qty,
  }) {
    _favoriteController.toggleFavorite(
      CartItem(
        id: productId,
        name: name,
        company: company,
        quantity: qty > 0 ? qty : 1,
        price: price,
        unit: unit,
        discountPercentage: discount,
        imageUrl: imageUrl,
        category: category,
        subItemName: subItemName,
        details: details,
        isPackage: false,
        colors: colors,
      ),
    );
  }

  void _addToCart({
    required String productId,
    required String name,
    required String company,
    required double price,
    required String unit,
    required double discount,
    required String imageUrl,
    required String category,
    required String subItemName,
    required List<String>? colors,
    required String details,
  }) {
    setState(() => quantities[name] = 1);

    _cartController.addItemToCart(
      CartItem(
        id: productId,
        name: name,
        company: company,
        quantity: 1,
        price: price,
        unit: unit,
        discountPercentage: discount,
        imageUrl: imageUrl,
        category: category,
        subItemName: subItemName,
        details: details,
        isPackage: false,
        colors: colors,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('কার্টে যুক্ত হয়েছে'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
