// File: lib/madmin/screens/category_form_screen.dart

import 'package:amar_uddokta/madmin/models/category_model.dart';
import 'package:amar_uddokta/madmin/services/firestore_service.dart';
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
      // লোডিং ইন্ডিকেটর দেখানোর জন্য একটি ডায়ালগ খুলুন (ঐচ্ছিক)
      // showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

      try {
        final String name = _nameController.text;
        final String icon = _iconController.text;
        final int order = int.tryParse(_orderController.text) ?? 0;

        if (widget.category == null) {
          // নতুন ক্যাটাগরি যোগ করা হচ্ছে
          final newCategory = ProductCategory(
            // গুরুত্বপূর্ণ: id এবং timestamps null রাখুন
            id: null, 
            categoriesName: name,
            categoriesIcon: icon,
            isActive: _isActive,
            order: order,
          );
          await _firestoreService.addCategory(newCategory);
        } else {
          // বিদ্যমান ক্যাটাগরি আপডেট করা হচ্ছে
          final updatedCategory = widget.category!.copyWith(
            categoriesName: name,
            categoriesIcon: icon,
            isActive: _isActive,
            order: order,
          );
          await _firestoreService.updateCategory(updatedCategory);
        }
        
        // নিশ্চিত করুন যে উইজেটটি এখনও স্ক্রিনে আছে
        if (mounted) {
          Navigator.of(context).pop(); // ফর্ম স্ক্রিন বন্ধ করুন
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.category == null ? 'ক্যাটাগরি সফলভাবে যোগ করা হয়েছে' : 'ক্যাটাগরি সফলভাবে আপডেট করা হয়েছে'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // যেকোনো এরর হ্যান্ডেল করুন
        print('Error saving category: $e');
        if (mounted) {
          Navigator.of(context).pop(); // লোডিং ডায়ালগ থাকলে তা বন্ধ করুন
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('সমস্যা হয়েছে: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'নতুন ক্যাটাগরি যোগ করুন' : 'ক্যাটাগরি সম্পাদনা করুন'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ক্যাটাগরির নাম'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'অনুগ্রহ করে একটি ক্যাটাগরির নাম লিখুন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _iconController,
                decoration: const InputDecoration(labelText: 'আইকন (ইমোজি)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'অনুগ্রহ করে একটি ইমোজি দিন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(labelText: 'ক্রম (সংখ্যা)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'অনুগ্রহ করে একটি ক্রম সংখ্যা দিন';
                  }
                  if (int.tryParse(value) == null) {
                    return 'অনুগ্রহ করে একটি বৈধ সংখ্যা দিন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('সক্রিয়:'),
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
                child: Text(widget.category == null ? 'যোগ করুন' : 'আপডেট করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}