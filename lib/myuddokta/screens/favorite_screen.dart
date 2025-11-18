// ignore_for_file: unused_import

import 'package:amar_uddokta/myuddokta/controllers/cart_controller.dart';
import 'package:amar_uddokta/myuddokta/models/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amar_uddokta/myuddokta/controllers/favorite_controller.dart';
import 'package:amar_uddokta/myuddokta/widgets/background_container.dart';

class FavoriteScreen extends StatelessWidget {
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final CartController cartController = Get.find<CartController>();

  FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('পছন্দের তালিকা'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Obx(
          () {
            if (favoriteController.favoriteItems.isEmpty) {
              return const Center(
                child: Text('আপনার পছন্দের তালিকায় কোনো আইটেম নেই'),
              );
            }
            return ListView.builder(
              itemCount: favoriteController.favoriteItems.length,
              itemBuilder: (context, index) {
                final item = favoriteController.favoriteItems[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Image.network(
                        item.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(item.name),
                      subtitle: Text('৳${item.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () {
                              cartController.addItemToCart(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${item.name} কার্টে যুক্ত হয়েছে'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              favoriteController.removeFromFavorites(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${item.name} পছন্দের তালিকা থেকে সরানো হয়েছে'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
