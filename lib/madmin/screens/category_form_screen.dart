import 'package:amar_uddokta/madmin/models/category_model.dart';
import 'package:amar_uddokta/madmin/services/firestore_service.dart'; // This service now uses Supabase
import 'package:flutter/material.dart';

class CategoryFormScreen extends StatefulWidget {
  final ProductCategory? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  bool _isActive = true;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.categoriesName;
      _iconController.text = widget.category!.categoriesIcon;
      _orderController.text = widget.category!.order.toString();
      _isActive = widget.category!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text;
      final String icon = _iconController.text;
      final int order = int.tryParse(_orderController.text) ?? 0;

      if (widget.category == null) {
        // Add new category - generate a unique int ID
        final newCategory = ProductCategory(
          id: DateTime.now().millisecondsSinceEpoch, // Generate a unique int ID
          categoriesName: name,
          categoriesIcon: icon,
          isActive: _isActive,
          order: order,
          adminCreatedAt: DateTime.now(),
          adminUpdatedAt: DateTime.now(),
        );
        await _firestoreService.addCategory(newCategory);
      } else {
        // Update existing category
        final updatedCategory = widget.category!.copyWith(
          id: widget.category!.id, // Ensure ID is passed for update
          categoriesName: name,
          categoriesIcon: icon,
          isActive: _isActive,
          order: order,
          adminUpdatedAt: DateTime.now(),
        );
        await _firestoreService.updateCategory(updatedCategory);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Changed Column to ListView to prevent overflow
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(labelText: 'Emoji'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an emoji';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(labelText: 'Order (Number)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an order number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Is Active:'),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCategory,
                child: Text(widget.category == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
