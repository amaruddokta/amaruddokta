import 'package:flutter/material.dart';
import 'package:amar_uddokta/uddoktaa/widgets/all_items_list.dart'; // Import AllItemsList

class SearchResultsScreen extends StatelessWidget {
  final String searchQuery;

  const SearchResultsScreen({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "$searchQuery"'),
      ),
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth > 1200) {
              crossAxisCount = 5;
            } else if (constraints.maxWidth > 800) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 3;
            }
            return AllItemsList(
              categoryName: '', // No specific category for search results
              searchQuery: searchQuery,
              crossAxisCount: crossAxisCount,
            );
          },
        ),
      ),
    );
  }
}
