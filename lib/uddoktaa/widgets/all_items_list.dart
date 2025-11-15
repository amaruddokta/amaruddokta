import 'package:amar_uddokta/uddoktaa/screens/product_details_screen.dart';
import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:amar_uddokta/uddoktaa/controllers/favorite_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/uddoktaa/controllers/cart_controller.dart';
import 'package:amar_uddokta/uddoktaa/models/cart_item.dart';

class AllItemsList extends StatefulWidget {
  final String categoryName;
  final String searchQuery;
  final int crossAxisCount;

  const AllItemsList(
      {Key? key,
      required this.categoryName,
      this.searchQuery = '',
      this.crossAxisCount = 2})
      : super(key: key);

  @override
  State<AllItemsList> createState() => _AllItemsListState();
}

class _AllItemsListState extends State<AllItemsList> {
  final CartController cartController = Get.find<CartController>();
  final FavoriteController favoriteController = Get.put(FavoriteController());
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, int> quantities = {};
  late Future<List<Map<String, dynamic>>> futureProducts;

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('কোনো প্রোডাক্ট পাওয়া যায়নি'));
        }

        final products = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: 0.6,
            crossAxisSpacing: 3,
            mainAxisSpacing: 5,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final name = product['name'] ?? 'Unknown';
            final price = (product['price'] ?? 0).toDouble();
            final unit = product['unit'] ?? '';
            final discount = (product['discount'] ?? 0);
            final imageUrl = product['imageUrl'] ?? '';
            final company = product['company'] ?? 'Unknown';
            final details = product['details'] ?? '';
            final stock = product['stock'] ?? 0;
            final subItemName = (product['subItemName'] ?? 'Others')
                .toString(); // Keep subItemName for CartItem

            List<String>? colors;
            final colorsData = product['colors'];
            if (colorsData is List) {
              colors = colorsData.map((e) => e.toString()).toList();
            } else if (colorsData is String) {
              colors = colorsData.split(',').map((e) => e.trim()).toList();
            }

            final qty = quantities[product['id'] ?? name] ?? 0;
            final discountedPrice =
                (price * (100 - discount) / 100).toStringAsFixed(2);

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
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
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
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
                        if (discount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
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
                                favoriteController
                                        .isFavorite(product['id'] ?? name)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favoriteController
                                        .isFavorite(product['id'] ?? name)
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () {
                                favoriteController.toggleFavorite(
                                  CartItem(
                                    id: product['id'] ?? name,
                                    name: name,
                                    company: company,
                                    quantity: qty > 0 ? qty : 1,
                                    price: price,
                                    unit: unit,
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '৳$discountedPrice',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5.0, vertical: 6.0),
                    child: stock == 0
                        ? const ElevatedButton(
                            onPressed: null,
                            child: Text('স্টক নেই'),
                          )
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailsScreen(
                                          product: product,
                                          productId: product['id'] ?? '',
                                        ),
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
                                      price: price,
                                      unit: unit,
                                      discountPercentage: discount.toDouble(),
                                      imageUrl: imageUrl,
                                      category: widget.categoryName,
                                      subItemName: subItemName,
                                      details: details,
                                      isPackage: false,
                                      colors: colors,
                                    ));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('কার্টে যুক্ত হয়েছে'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('অর্ডার করুন'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
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
                                          builder: (context) =>
                                              ProductDetailsScreen(
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
                                          color: const Color.fromARGB(
                                              255, 191, 27, 27)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove,
                                              size: 18),
                                          onPressed: () {
                                            cartController.decreaseQuantity(
                                                product['id'] ?? name,
                                                color: null,
                                                size: null);
                                          },
                                        ),
                                        Text(
                                          '$qty',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          onPressed: () {
                                            cartController.increaseQuantity(
                                                product['id'] ?? name,
                                                color: null,
                                                size: null);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
