import 'package:amar_uddokta/uddoktaa/screens/product_details_screen.dart';
import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:amar_uddokta/uddoktaa/controllers/favorite_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/uddoktaa/controllers/cart_controller.dart';
import 'package:amar_uddokta/uddoktaa/models/cart_item.dart';

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

class _SubItemScreenState extends State<SubItemScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CartController _cartController = Get.find<CartController>();
  final FavoriteController _favoriteController = Get.find<FavoriteController>();
  Map<String, int> quantities = {};
  late Future<List<Map<String, dynamic>>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetchProducts();
    _setupCartListener();
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
    }
  }

  // UPDATED: Now fetches category name using a JOIN
  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final List<Map<String, dynamic>> response =
          await _supabase.from('ponno').select('''
            *,
            categories (
              categories_name
            )
          ''');

      final allProducts = response.map((data) {
        return data;
      }).toList();

      final filteredProducts = allProducts.where((product) {
        // UPDATED: Access category name from the nested 'categories' object
        final matchesCategory = widget.categoryName.isEmpty ||
            (product['categories']?['categories_name'] ?? '')
                    .toString()
                    .trim() ==
                widget.categoryName.trim();

        final matchesSearch = (product['usernames'] ?? '')
            .toString()
            .toLowerCase()
            .contains(widget.searchQuery.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();

      return filteredProducts;
    } catch (e) {
      debugPrint('পণ্য লোড করতে সমস্যা: $e');
      return [];
    }
  }

  List<String> _getColorsList(dynamic colorsData) {
    if (colorsData == null) return [];
    if (colorsData is List) {
      return colorsData.map((e) => e.toString()).toList();
    } else if (colorsData is String) {
      return colorsData.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _getSizesWithDetails(dynamic sizesData) {
    if (sizesData == null) return [];
    if (sizesData is List) {
      return sizesData.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.categoryName),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            } else if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyWidget();
            }

            return _buildProductGrid(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorWidget(String error) {
    return Center(child: Text('ত্রুটি: $error'));
  }

  Widget _buildEmptyWidget() {
    return const Center(child: Text('কোনো প্রোডাক্ট পাওয়া যায়নি'));
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    final groupedProducts = _groupProductsBySubItem(products);

    return ListView(
      children: groupedProducts.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubItemHeader(entry.key),
            _buildProductsGrid(entry.value),
          ],
        );
      }).toList(),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupProductsBySubItem(
      List<Map<String, dynamic>> products) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var product in products) {
      final subItem = (product['userItem'] ?? 'Others').toString();
      grouped.putIfAbsent(subItem, () => []).add(product);
    }
    return grouped;
  }

  Widget _buildSubItemHeader(String subItemName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        subItemName,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProductsGrid(List<Map<String, dynamic>> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 3,
        mainAxisSpacing: 5,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  Map<String, dynamic> _getFirstSizePriceUnit(List<dynamic>? sizesData) {
    if (sizesData == null || sizesData.isEmpty) {
      return {};
    }
    return sizesData.first as Map<String, dynamic>;
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['usernames'] ?? 'Unknown';
    final sizes = _getSizesWithDetails(product['sizes']);
    double displayPrice = (product['price'] ?? 0).toDouble();
    String displayUnit =
        product['unit']?.toString() ?? ''; // Ensure unit is string

    if (sizes.isNotEmpty) {
      final firstSizeDetails = _getFirstSizePriceUnit(sizes.cast<dynamic>());
      if (firstSizeDetails.isNotEmpty) {
        displayPrice = (firstSizeDetails['price'] ?? 0).toDouble();
        displayUnit =
            firstSizeDetails['unit']?.toString() ?? ''; // Ensure unit is string
      }
    }

    final discount = (product['userdiscounts'] ?? 0).toInt();
    final imageUrl =
        product['userimageUrls']?.toString() ?? ''; // Ensure imageUrl is string
    final company = product['userscompanys'] ?? 'Unknown';
    final details =
        product['userdetailss']?.toString() ?? ''; // Ensure details is string
    final stock = (product['userstocks'] ?? 0).toInt();
    final subItemName = (product['userItem'] ?? 'Others').toString();
    final productId =
        product['id']?.toString() ?? name; // Ensure productId is string
    // UPDATED: Access category name from nested object
    final category = product['categories']?['categories_name']?.toString() ??
        widget.categoryName; // Ensure category is string

    final colors = _getColorsList(product['usercolors']);
    final qty = quantities[productId] ?? 0;
    final discountedPrice =
        (displayPrice * (100 - discount) / 100).toStringAsFixed(2);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          _buildProductInfo(
              name, displayPrice, discountedPrice, discount, displayUnit),
          Expanded(
            child: _buildOrderButton(
              product: product,
              productId: productId,
              name: name,
              company: company,
              price: displayPrice,
              unit: displayUnit,
              discount: discount.toDouble(),
              imageUrl: imageUrl,
              category: category,
              subItemName: subItemName,
              details: details,
              colors: colors,
              stock: stock,
              qty: qty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(
    String imageUrl,
    int discount,
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
      height: 180,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _navigateToProductDetails(product),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                color: Colors.grey[200],
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image,
                          size: 40, color: Colors.grey),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-$discount%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            child: Obx(
              () => IconButton(
                icon: Icon(
                  _favoriteController.isFavorite(productId)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _favoriteController.isFavorite(productId)
                      ? Colors.red
                      : null,
                ),
                onPressed: () => _toggleFavorite(
                  productId: productId,
                  name: name,
                  company: company,
                  price: price,
                  unit: unit,
                  discount: discount.toDouble(),
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
          if (stock == 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
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

  Widget _buildProductInfo(
    String name,
    double price,
    String discountedPrice,
    int discount,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              if (discount > 0)
                Text(
                  '৳${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 6.0),
      child: stock == 0
          ? const ElevatedButton(onPressed: null, child: Text('স্টক নেই'))
          : qty == 0
              ? ElevatedButton.icon(
                  onPressed: () {
                    final colorsData = product['usercolors'];
                    final sizesData = product['sizes'];

                    final bool hasColors = colorsData != null &&
                        (colorsData is List
                            ? colorsData.isNotEmpty
                            : (colorsData?.toString() ?? '')
                                .isNotEmpty); // Safely check string
                    final bool hasSizes = sizesData != null &&
                        (sizesData is List
                            ? sizesData.isNotEmpty
                            : (sizesData?.toString() ?? '')
                                .isNotEmpty); // Safely check string

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
                  icon: const Icon(Icons.add_circle_outline),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('অর্ডার করুন'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                )
              : Builder(builder: (context) {
                  final colorsData = product['usercolors'];
                  final sizesData = product['sizes'];
                  final bool hasColors = colorsData != null &&
                      (colorsData is List
                          ? colorsData.isNotEmpty
                          : (colorsData as String).isNotEmpty);
                  final bool hasSizes = sizesData != null &&
                      (sizesData is List
                          ? sizesData.isNotEmpty
                          : (sizesData as String).isNotEmpty);
                  final bool hasOptions = hasColors || hasSizes;

                  if (hasOptions) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsScreen(
                              product: product,
                              productId: (product['id'] ?? '').toString(),
                            ),
                          ),
                        );
                      },
                      child: const Text('Details'),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color.fromARGB(255, 191, 27, 27)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () {
                              _cartController.decreaseQuantity(productId,
                                  color: null, size: null);
                            },
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              _cartController.increaseQuantity(productId,
                                  color: null, size: null);
                            },
                          ),
                        ],
                      ),
                    );
                  }
                }),
    );
  }

  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          product: product,
          productId: (product['id'] ?? '').toString(),
        ),
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
        imageUrl: imageUrl.toString(), // Ensure imageUrl is string
        category: category,
        subItemName: subItemName,
        details: details.toString(), // Ensure details is string
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
    setState(() => quantities[productId] = 1);

    _cartController.addItemToCart(
      CartItem(
        id: productId,
        name: name,
        company: company,
        quantity: 1,
        price: price,
        unit: unit,
        discountPercentage: discount,
        imageUrl: imageUrl.toString(), // Ensure imageUrl is string
        category: category,
        subItemName: subItemName,
        details: details.toString(), // Ensure details is string
        isPackage: false,
        colors: colors,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('কার্টে যুক্ত হয়েছে'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
