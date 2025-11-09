import 'package:amar_uddokta/uddoktaa/screens/product_details_screen.dart';
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
      {super.key,
      required this.categoryName,
      this.searchQuery = '',
      this.crossAxisCount = 2});

  @override
  State<AllItemsList> createState() => _AllItemsListState();
}

class _AllItemsListState extends State<AllItemsList> {
  final CartController cartController = Get.find<CartController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();
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

  // UPDATED: Now fetches category name using a JOIN
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final List<Map<String, dynamic>> response =
          await Supabase.instance.client.from('ponno').select('''
            *,
            categories (
              categories_name
            )
          ''');
      final allProducts = response.map((data) {
        return data;
      }).toList();

      // UPDATED: Access category name from the nested 'categories' object
      final filteredByCategory = widget.categoryName.isEmpty
          ? allProducts
          : allProducts.where((product) {
              final category = (product['categories']?['categories_name'] ?? '')
                  .toString()
                  .trim();
              return category == widget.categoryName.trim();
            }).toList();

      final filteredBySearch = filteredByCategory.where((product) {
        final name = (product['usernames'] ?? '').toString().toLowerCase();
        return name.contains(widget.searchQuery.toLowerCase());
      }).toList();

      for (var product in filteredBySearch) {
        final id = product['id'] ?? product['usernames'];
        if (id != null) {
          quantities.putIfAbsent(id, () => 0);
        }
      }
      final cartItems = cartController.cartItems;
      for (var item in cartItems) {
        if (quantities.containsKey(item.id)) {
          quantities[item.id] = item.quantity;
        }
      }

      filteredBySearch.shuffle();
      return filteredBySearch;
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
            final name = product['usernames'] ?? 'Unknown';
            final sizes = _getSizesWithDetails(product['sizes']);
            double price = (product['price'] ?? 0).toDouble();
            String unit = product['unit'] ?? '';

            if (sizes.isNotEmpty) {
              final firstSizeDetails = sizes.first;
              price = (firstSizeDetails['price'] ?? 0).toDouble();
              unit = firstSizeDetails['unit'] ?? '';
            }

            final discount = (product['userdiscounts'] ?? 0).toDouble();
            final imageUrl = product['userimageUrls'] ?? '';
            final company = product['userscompanys'] ?? 'Unknown';
            final details = product['userdetailss'] ?? '';
            final stock = product['userstocks'] ?? 0;
            final subItemName = (product['userItem'] ?? 'Others').toString();
            final productId = product['id'] ?? name;
            // UPDATED: Access category name from nested object
            final category = product['categories']?['categories_name'] ??
                widget.categoryName;

            List<String>? colors;
            final colorsData = product['usercolors'];
            if (colorsData is List) {
              colors = colorsData.map((e) => e.toString()).toList();
            } else if (colorsData is String) {
              colors = colorsData.split(',').map((e) => e.trim()).toList();
            }

            final qty = quantities[productId] ?? 0;
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
                                  productId: productId.toString(),
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
                                '-${discount.toInt()}%',
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
                                favoriteController.isFavorite(productId)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favoriteController.isFavorite(productId)
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () {
                                favoriteController.toggleFavorite(
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

                                  if (hasColors || hasSizes) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailsScreen(
                                          product: product,
                                          productId: productId.toString(),
                                        ),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      quantities[productId] = 1;
                                    });
                                    cartController.addItemToCart(CartItem(
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
                                          builder: (context) =>
                                              ProductDetailsScreen(
                                            product: product,
                                            productId: productId.toString(),
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
                                                productId,
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
                                                productId,
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
