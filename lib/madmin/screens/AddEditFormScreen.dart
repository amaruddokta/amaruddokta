// ignore_for_file: unused_import

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class AddEditFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AddEditFormScreen({super.key, this.product});

  @override
  State<AddEditFormScreen> createState() => _AddEditFormScreenState();
}

class _AddEditFormScreenState extends State<AddEditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String? selectedCategory;
  String? selectedCompany;
  File? imageFile;
  String? imageUrl;

  List<String> categories = [];
  List<String> companies = [];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      nameController.text = widget.product!['name'];
      priceController.text = widget.product!['price'].toString();
      imageUrl = widget.product!['imageUrl'];
    }
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    final categoryResponse =
        await Supabase.instance.client.from('categories').select('name');
    final companyResponse =
        await Supabase.instance.client.from('companies').select('name');

    setState(() {
      categories = (categoryResponse as List)
          .map((item) => item['name'].toString())
          .toList();
      companies = (companyResponse as List)
          .map((item) => item['name'].toString())
          .toList();

      final loadedCategory = widget.product?['category'];
      final loadedCompany = widget.product?['company'];

      selectedCategory =
          categories.contains(loadedCategory) ? loadedCategory : null;
      selectedCompany =
          companies.contains(loadedCompany) ? loadedCompany : null;
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => imageFile = File(pickedFile.path));
    }
  }

  Future<String> uploadImage(File image) async {
    final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage
        .from('products')
        .upload(fileName, image);
    return Supabase.instance.client.storage
        .from('products')
        .getPublicUrl(fileName);
  }

  void saveProduct() async {
    if (_formKey.currentState!.validate()) {
      String name = nameController.text;
      double price = double.tryParse(priceController.text) ?? 0;

      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile!);
      }

      final data = {
        'name': name,
        'price': price,
        'category': selectedCategory,
        'company': selectedCompany,
        'imageUrl': imageUrl ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (widget.product == null) {
        await Supabase.instance.client.from('products').insert(data);
      } else {
        await Supabase.instance.client
            .from('products')
            .update(data)
            .eq('id', widget.product!['id']);
      }

      Navigator.pop(context);
    }
  }

  void deleteProduct() async {
    if (widget.product != null) {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', widget.product!['id']);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.product == null ? 'নতুন প্রোডাক্ট' : 'প্রোডাক্ট এডিট করুন'),
        actions: widget.product != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: deleteProduct,
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'প্রোডাক্ট নাম'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'প্রোডাক্ট নাম দিন' : null,
              ),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'দাম'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'দাম দিন' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: categories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
                validator: (value) =>
                    value == null ? 'ক্যাটাগরি নির্বাচন করুন' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedCompany,
                items: companies
                    .map((comp) =>
                        DropdownMenuItem(value: comp, child: Text(comp)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCompany = val),
                decoration: const InputDecoration(labelText: 'কোম্পানি'),
                validator: (value) =>
                    value == null ? 'কোম্পানি নির্বাচন করুন' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('ছবি নির্বাচন করুন'),
                onPressed: pickImage,
              ),
              if (imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(imageFile!, height: 120),
                )
              else if (imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(imageUrl!, height: 120),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveProduct,
                child: const Text('সেভ করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
