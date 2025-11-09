// File: lib/screens/category_home_screen.dart

import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:flutter/material.dart';

class CategoryHomeScreen extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;

  const CategoryHomeScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('$categoryIcon  $categoryName'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Showing products for $categoryName',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
