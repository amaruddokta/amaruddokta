// File: lib/screens/category_form_screen.dart
import 'package:amar_uddokta/madmin/models/category_model.dart';
import 'package:amar_uddokta/madmin/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // UUID প্যাকেজ ইমপোর্ট করুন

class CategoryFormScreen extends StatefulWidget {
  final ProductCategory? category;

  const CategoryFormScreen({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  bool _isActive = true;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _iconController.text = widget.category!.icon;
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
        // Add new category
        final newCategory = ProductCategory(
          id: const Uuid().v4(), // UUID তৈরি করুন
          name: name,
          icon: icon,
          isActive: _isActive,
          order: order,
        );
        await _supabaseService.addCategory(newCategory);
      } else {
        // Update existing category
        final updatedCategory = widget.category!.copyWith(
          name: name,
          icon: icon,
          isActive: _isActive,
          order: order,
        );
        await _supabaseService.updateCategory(updatedCategory);
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
