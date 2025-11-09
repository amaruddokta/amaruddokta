import 'package:amar_uddokta/madmin/models/category_model.dart';
import 'package:amar_uddokta/madmin/screens/category_form_screen.dart';
import 'package:amar_uddokta/madmin/services/firestore_service.dart'; // This service now uses Supabase
import 'package:flutter/material.dart';

class CategoryAdminScreen extends StatefulWidget {
  const CategoryAdminScreen({super.key});

  @override
  State<CategoryAdminScreen> createState() => _CategoryAdminScreenState();
}

class _CategoryAdminScreenState extends State<CategoryAdminScreen> {
  final FirestoreService _firestoreService = FirestoreService();

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
        stream: _firestoreService.getCategories(),
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
                  leading: category.categoriesIcon.isNotEmpty
                      ? Text(
                          category.categoriesIcon,
                          style: const TextStyle(fontSize: 30),
                        )
                      : const Icon(Icons.category),
                  title: Text(category.categoriesName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order: ${category.order}'),
                      Text('Active: ${category.isActive ? 'Yes' : 'No'}'),
                      if (category.adminCreatedAt != null)
                        Text(
                            'Created: ${category.adminCreatedAt!.toLocal().toString().split('.')[0]}'),
                      if (category.adminUpdatedAt != null)
                        Text(
                            'Updated: ${category.adminUpdatedAt!.toLocal().toString().split('.')[0]}'),
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
                                    'Are you sure you want to delete category "${category.categoriesName}"?'),
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
                            if (category.id != null) {
                              await _firestoreService
                                  .deleteCategory(category.id!);
                            } else {
                              // Handle case where category.id is null, perhaps show an error
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Category ID is missing!')),
                              );
                            }
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
