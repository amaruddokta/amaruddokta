import 'package:flutter/material.dart';
import 'package:amar_uddokta/uddoktaa/screens/search_results_screen.dart';

class SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final double? height;
  final double? width;

  const SearchBox(
      {super.key, required this.onChanged, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'পণ্য খুঁজুন...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          onChanged: (query) {
            onChanged(query);
            if (query.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsScreen(searchQuery: query),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
