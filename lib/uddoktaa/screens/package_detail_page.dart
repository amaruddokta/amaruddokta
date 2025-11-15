// lib/screens/package_detail_page.dart
// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors

import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/package_model.dart' as package_model;
import '../controllers/cart_controller.dart';
import '../models/cart_item.dart';

class PackageDetailPage extends StatelessWidget {
  final package_model.Package package;
  final CartController cartController = Get.find<CartController>();

  PackageDetailPage({required this.package});

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(package.name),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ছবি
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: package.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) =>
                      Center(child: Icon(Icons.broken_image, size: 60)),
                ),
              ),
              SizedBox(height: 16),

              // বিবরণ
              Text('বিবরণ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(package.description),

              SizedBox(height: 16),
              // দাম ও ছাড়
              Text('মূল্য: ৳${package.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 16)),

              Text(
                'ছাড়ের পরিমাণ: ৳${(package.totalPrice - package.discountedPrice).toStringAsFixed(0)}',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              Text(
                'ছাড়ের পর মূল্য: ৳${package.discountedPrice.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),

              SizedBox(height: 24),
              // পণ্যের তালিকা
              Text('এই প্যাকেজে যা থাকছে:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),

              // থাম্বনেল সহ তালিকা
              ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: package.products.length,
                separatorBuilder: (_, __) => SizedBox(height: 4),
                itemBuilder: (ctx, idx) {
                  final item = package.products[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                    title: Text('${item.name} ${item.quantity}',
                        style: TextStyle(fontSize: 16)),
                    subtitle: Text(
                        'Unit Price: ৳${item.unitPrice.toStringAsFixed(2)}'),
                    onTap: () =>
                        _showProductImage(context, item.name, item.imageUrl),
                  );
                },
              ),

              SizedBox(height: 32),
              // অর্ডার করুন বাটন
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    cartController.addItemToCart(CartItem(
                      id: package.id,
                      name: package.name,
                      company: 'প্যাকেজ',
                      quantity: 1,
                      price: package.discountedPrice,
                      unit: 'প্যাকেজ',
                      discountPercentage: package.discountPercentage,
                      imageUrl: package.imageUrl,
                      category: 'প্যাকেজ',
                      subItemName: '',
                      details: package.description,
                      isPackage: true,
                    ));
                    Get.snackbar(
                      'অর্ডার',
                      'প্যাকেজটি কার্টে যোগ হয়েছে',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: Text('অর্ডার করুন'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductImage(BuildContext context, String name, String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) =>
              Center(child: Icon(Icons.broken_image, size: 60)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }
}
