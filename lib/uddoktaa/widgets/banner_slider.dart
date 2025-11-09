// File: lib/widgets/banner_slider.dart
// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/package_model.dart' as package_model;
import '../screens/package_detail_page.dart';

/// ব্যানার স্লাইডার উইজেট
class BannerSlider extends StatelessWidget {
  final List<package_model.Package> packages;

  const BannerSlider({required this.packages});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 130.0,
        autoPlay: true,
        enlargeCenterPage: false,
        viewportFraction: 0.9,
        autoPlayInterval: Duration(seconds: 3),
      ),
      items: packages.map((pkg) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PackageDetailPage(package: pkg),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: pkg.pacImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, u) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (c, u, e) =>
                        Center(child: Icon(Icons.broken_image)),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            'মূল্য: ৳${pkg.pacTotalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 228, 14, 14),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ছাড়ের পর মূল্য: ৳${pkg.pacDiscountedPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 205, 22, 150),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
