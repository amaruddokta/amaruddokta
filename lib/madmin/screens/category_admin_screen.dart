// File: lib/screens/category_admin_screen.dart
import 'package:amar_uddokta/madmin/models/category_model.dart';
import 'package:amar_uddokta/madmin/screens/category_form_screen.dart';
import 'package:amar_uddokta/madmin/services/supabase_service.dart';
import 'package:flutter/material.dart';

class CategoryAdminScreen extends StatefulWidget {
  const CategoryAdminScreen({Key? key}) : super(key: key);

  @override
  State<CategoryAdminScreen> createState() => _CategoryAdminScreenState();
}

class _CategoryAdminScreenState extends State<CategoryAdminScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CategoryFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ProductCategory>>(
        stream: _supabaseService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: category.icon.isNotEmpty
                      ? Text(
                          category.icon,
                          style: const TextStyle(fontSize: 30),
                        )
                      : const Icon(Icons.category),
                  title: Text(category.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order: ${category.order}'),
                      Text('Active: ${category.isActive ? 'Yes' : 'No'}'),
                      if (category.createdAt != null)
                        Text(
                            'Created: ${category.createdAt!.toLocal().toString().split('.')[0]}'),
                      if (category.updatedAt != null)
                        Text(
                            'Updated: ${category.updatedAt!.toLocal().toString().split('.')[0]}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CategoryFormScreen(category: category),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final bool confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: Text(
                                    'Are you sure you want to delete category "${category.name}"?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            await _supabaseService.deleteCategory(category.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
