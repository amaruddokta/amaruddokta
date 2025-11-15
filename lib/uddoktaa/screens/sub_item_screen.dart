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
    Key? key,
    required this.categoryName,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  State<SubItemScreen> createState() => _SubItemScreenState();
}

class _SubItemScreenState extends State<SubItemScreen> {
  final CartController _cartController = Get.find<CartController>();
  final FavoriteController _favoriteController = Get.find<FavoriteController>();
  final SupabaseClient _supabase = Supabase.instance.client;
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

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      // The select() method in supabase_flutter typically returns a PostgrestResponse.
      // However, the error message indicates that 'response' is of type PostgrestList.
      // This suggests that the select() call might be returning the data directly,
      // and errors are handled via exceptions.
      final response = await _supabase.from('products').select();

      // If 'response' is a PostgrestList, it implies the data was fetched successfully.
      // Errors would have been thrown as exceptions and caught by the try-catch block.
      // Therefore, we can directly cast 'response' to the expected list type.
      final allProducts = List<Map<String, dynamic>>.from(response as List);

      // Filtering logic
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
    } catch (e) {
      debugPrint('পণ্য লোড করতে সমস্যা: $e');
      return [];
    }
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
      final subItem = (product['subItemName'] ?? 'Others').toString();
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Unknown';
    final price = (product['price'] ?? 0).toDouble();
    final unit = product['unit'] ?? '';
    final discount = (product['discount'] ?? 0).toInt();
    final imageUrl = product['imageUrl'] ?? '';
    final company = product['company'] ?? 'Unknown';
    final details = product['details'] ?? '';
    final stock = (product['stock'] ?? 0).toInt();
    final subItemName = (product['subItemName'] ?? 'Others').toString();
    final productId = product['id'] ?? name;
    final category = product['category'] ?? widget.categoryName;

    final colors = _getColorsList(product['colors']);
    final qty = quantities[product['id'] ?? name] ?? 0;
    final discountedPrice = (price * (100 - discount) / 100).toStringAsFixed(2);

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
            price,
            unit,
            category,
            subItemName,
            details,
            qty,
            product,
          ),
          Expanded(
            child: _buildProductInfo(name, price, discountedPrice, discount),
          ),
          Expanded(
            child: _buildOrderButton(
              product: product,
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
    debugPrint('Image URL: $imageUrl');
    return SizedBox(
      height: 180, // উচ্চতা বাড়িয়ে দেওয়া হয়েছে
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
                color: Colors.grey[200], // পটভূমির রং যোগ করা হয়েছে
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover, // BoxFit.cover ব্যবহার করা হয়েছে
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Image loading error for URL $imageUrl: $error');
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
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
          const SizedBox(height: 0),
          Row(
            children: [
              Text(
                '৳$discountedPrice',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              if (discount > 0)
                Expanded(
                  child: Text(
                    '৳${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
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
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      child: stock == 0
          ? const ElevatedButton(onPressed: null, child: Text('স্টক নেই'))
          : qty == 0
              ? ElevatedButton.icon(
                  onPressed: () {
                    final colorsData = product['colors'];
                    final sizesData = product['size'];

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
                  icon: const Icon(Icons.add_circle_outline),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('অর্ডার করুন'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                )
              : Builder(builder: (context) {
                  final colorsData = product['colors'];
                  final sizesData = product['size'];
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
                              productId: product['id'] ?? '',
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
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          product: product,
          productId: product['id'] ?? '',
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
      const SnackBar(
        content: Text('কার্টে যুক্ত হয়েছে'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
