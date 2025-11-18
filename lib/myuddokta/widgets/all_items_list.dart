import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:amar_uddokta/myuddokta/screens/product_details_screen.dart';
import 'package:amar_uddokta/myuddokta/controllers/favorite_controller.dart';
import 'package:amar_uddokta/myuddokta/controllers/cart_controller.dart';
import 'package:amar_uddokta/myuddokta/models/cart_item.dart';

class AllItemsList extends StatefulWidget {
  final String categoryName;
  final String searchQuery;
  final int crossAxisCount;

  const AllItemsList(
      {super.key,
      required this.categoryName,
      this.searchQuery = '',
      this.crossAxisCount = 2});

  @override
  State<AllItemsList> createState() => _AllItemsListState();
}

class _AllItemsListState extends State<AllItemsList>
    with TickerProviderStateMixin {
  final CartController cartController = Get.find<CartController>();
  final FavoriteController favoriteController = Get.put(FavoriteController());
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, int> quantities = {};
  late Future<List<Map<String, dynamic>>> futureProducts;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
    _setupCartListener();
    _setupAnimation();
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

  void _setupCartListener() {
    cartController.cartItems.listen((cartItems) {
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
  void didUpdateWidget(covariant AllItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.categoryName != widget.categoryName) {
      futureProducts = fetchProducts();
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final response = await _supabase.from('products').select();

      final allProducts = List<Map<String, dynamic>>.from(response as List);

      final filteredByCategory = widget.categoryName.isEmpty
          ? allProducts
          : allProducts.where((product) {
              final category = (product['category'] ?? '').toString().trim();
              return category == widget.categoryName.trim();
            }).toList();

      final filteredBySearch = filteredByCategory.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        return name.contains(widget.searchQuery.toLowerCase());
      }).toList();

      for (var product in filteredBySearch) {
        final name = product['name'];
        if (name != null) {
          quantities.putIfAbsent(name, () => 0);
        }
      }
      // Sync with cart controller
      final cartItems = cartController.cartItems;
      for (var item in cartItems) {
        if (quantities.containsKey(item.name)) {
          quantities[item.name] = item.quantity;
        }
      }

      filteredBySearch.shuffle(); // Randomize the order
      return filteredBySearch;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Map<String, dynamic> _getFirstSizePriceUnit(List<dynamic>? sizesData) {
    if (sizesData == null || sizesData.isEmpty) {
      return {};
    }
    return sizesData.first as Map<String, dynamic>;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyWidget();
          }

          final products = snapshot.data!;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              childAspectRatio: 0.65,
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
        },
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
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
                  futureProducts = fetchProducts();
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Unknown';
    double displayPrice = (product['price'] ?? 0).toDouble();
    String displayUnit = product['unit'] ?? '';
    final discount = (product['discount'] ?? 0).toDouble();
    final imageUrl = product['imageUrl'] ?? '';
    final company = product['company'] ?? 'Unknown';
    final details = product['details'] ?? '';
    final stock = product['stock'] ?? 0;
    final subItemName = (product['subItemName'] ?? 'Others')
        .toString(); // Keep subItemName for CartItem

    // Handle sizes data
    final List<dynamic>? sizesData = product['sizes'] as List<dynamic>?;
    if (sizesData != null && sizesData.isNotEmpty) {
      final firstSizeDetails = _getFirstSizePriceUnit(sizesData);
      if (firstSizeDetails.isNotEmpty) {
        displayPrice = (firstSizeDetails['price'] ?? 0).toDouble();
        displayUnit = firstSizeDetails['unit'] ?? '';
      }
    }

    List<String>? colors;
    final colorsData = product['colors'];
    if (colorsData is List) {
      colors = colorsData.map((e) => e.toString()).toList();
    } else if (colorsData is String) {
      colors = colorsData.split(',').map((e) => e.trim()).toList();
    }

    final qty = quantities[product['id'] ?? name] ?? 0;
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
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ProductDetailsScreen(
                            product: product,
                            productId: product['id'] ?? '',
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
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
                        tag: 'product-${product['id']}',
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                          '-$discount%',
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
                            favoriteController.isFavorite(product['id'] ?? name)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: favoriteController
                                    .isFavorite(product['id'] ?? name)
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                          onPressed: () {
                            favoriteController.toggleFavorite(
                              CartItem(
                                id: product['id'] ?? name,
                                name: name,
                                company: company,
                                quantity: qty > 0 ? qty : 1,
                                price: displayPrice,
                                unit: displayUnit,
                                discountPercentage: discount.toDouble(),
                                imageUrl: imageUrl,
                                category: widget.categoryName,
                                subItemName: subItemName,
                                details: details,
                                isPackage: false,
                                colors: colors,
                              ),
                            );
                          },
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
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                      ],
                    ),
                    _buildOrderButton(
                      product: product,
                      name: name,
                      company: company,
                      displayPrice: displayPrice,
                      displayUnit: displayUnit,
                      discount: discount,
                      imageUrl: imageUrl,
                      subItemName: subItemName,
                      details: details,
                      colors: colors,
                      stock: stock,
                      qty: qty,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton({
    required Map<String, dynamic> product,
    required String name,
    required String company,
    required double displayPrice,
    required String displayUnit,
    required double discount,
    required String imageUrl,
    required String subItemName,
    required String details,
    required List<String>? colors,
    required int stock,
    required int qty,
  }) {
    return stock == 0
        ? Container(
            height: 32,
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
                height: 32,
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
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ProductDetailsScreen(
                            product: product,
                            productId: product['id'] ?? '',
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                        ),
                      );
                    } else {
                      setState(() {
                        quantities[name] = 1;
                      });
                      cartController.addItemToCart(CartItem(
                        id: product['id'] ?? name,
                        name: name,
                        company: company,
                        quantity: 1,
                        price: displayPrice,
                        unit: displayUnit,
                        discountPercentage: discount.toDouble(),
                        imageUrl: imageUrl,
                        category: widget.categoryName,
                        subItemName: subItemName,
                        details: details,
                        isPackage: false,
                        colors: colors,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white),
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
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'অর্ডার করুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                height: 32,
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
                          cartController.decreaseQuantity(product['id'] ?? name,
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
                          cartController.increaseQuantity(product['id'] ?? name,
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
}
