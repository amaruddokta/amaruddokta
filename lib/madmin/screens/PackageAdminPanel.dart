import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class PackageAdminPanel extends StatefulWidget {
  const PackageAdminPanel({super.key});

  @override
  _PackageAdminPanelState createState() => _PackageAdminPanelState();
}

class _PackageAdminPanelState extends State<PackageAdminPanel> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _discountStringController =
      TextEditingController();
  final TextEditingController _discountPercentageController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productQuantityController =
      TextEditingController();
  final TextEditingController _productUnitPriceController =
      TextEditingController();
  final TextEditingController _productImageUrlController =
      TextEditingController();

  List<Map<String, dynamic>> _products = [];
  int? editingProductIndex;
  String? editingDocId;

  // Image Picker and Upload to Supabase Storage
  Future<void> pickImage(TextEditingController controller) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isUploading = true);
        final bytes = await pickedFile.readAsBytes();
        String fileExtension = path.extension(pickedFile.path);
        if (fileExtension.isEmpty || fileExtension == '.') {
          fileExtension = '.jpg';
        }
        final fileName =
            'banners/${DateTime.now().millisecondsSinceEpoch}$fileExtension'; // Upload to 'banners' folder
        await _supabase.storage.from('packages').uploadBinary(fileName, bytes);
        final uploadedUrl =
            _supabase.storage.from('packages').getPublicUrl(fileName);

        if (uploadedUrl.isNotEmpty) {
          controller.text = uploadedUrl;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ ইমেজ সফলভাবে আপলোড হয়েছে')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ইমেজ আপলোড ব্যর্থ হয়েছে')),
          );
        }
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ ত্রুটি: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void clearForm() {
    _nameController.clear();
    _imageUrlController.clear();
    _totalPriceController.clear();
    _discountStringController.clear();
    _discountPercentageController.clear();
    _descriptionController.clear();
    _productNameController.clear();
    _productQuantityController.clear();
    _productUnitPriceController.clear();
    _productImageUrlController.clear();
    _products = [];
    editingDocId = null;
    editingProductIndex = null;
    setState(() {});
  }

  void addOrUpdateProduct() {
    final name = _productNameController.text.trim();
    final quantity = _productQuantityController.text.trim();
    final unitPrice =
        double.tryParse(_productUnitPriceController.text.trim()) ?? 0;
    final imageUrl = _productImageUrlController.text.trim();

    if (name.isEmpty ||
        quantity.isEmpty ||
        unitPrice <= 0 ||
        imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("প্রোডাক্টের সব তথ্য সঠিকভাবে দিন")),
      );
      return;
    }

    final product = {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'imageUrl': imageUrl,
    };

    setState(() {
      if (editingProductIndex != null) {
        _products[editingProductIndex!] = product;
        editingProductIndex = null;
      } else {
        _products.add(product);
      }
      _productNameController.clear();
      _productQuantityController.clear();
      _productUnitPriceController.clear();
      _productImageUrlController.clear();
    });
  }

  void editProduct(int index) {
    final p = _products[index];
    _productNameController.text = p['name'];
    _productQuantityController.text = p['quantity'];
    _productUnitPriceController.text = p['unitPrice'].toString();
    _productImageUrlController.text = p['imageUrl'];
    setState(() {
      editingProductIndex = index;
    });
  }

  Future<void> removeProduct(int index) async {
    final productToRemove = _products[index];
    final imageUrl = productToRemove['imageUrl'] as String?;

    setState(() {
      _products.removeAt(index);
      if (editingProductIndex == index) {
        editingProductIndex = null;
        _productNameController.clear();
        _productQuantityController.clear();
        _productUnitPriceController.clear();
        _productImageUrlController.clear();
      }
    });

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final path = imageUrl.substring(imageUrl.indexOf('/o/') + 3);
        await _supabase.storage.from('packages').remove([path]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🗑️ প্রোডাক্টের ছবি সফলভাবে মুছে ফেলা হয়েছে।')),
        );
      } catch (e) {
        debugPrint('Error deleting product image from Supabase Storage: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ প্রোডাক্টের ছবি ডিলিটে সমস্যা: $e')),
        );
      }
    }
  }

  Future<void> savePackage() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final totalPrice = double.tryParse(_totalPriceController.text.trim()) ?? 0;
    final discountString = _discountStringController.text.trim();
    final discountPercentage =
        double.tryParse(_discountPercentageController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim();

    final discountedPrice = totalPrice * (1 - discountPercentage / 100);

    final packageData = {
      'pacName': name,
      'pacImageUrl': imageUrl,
      'pacTotalPrice': totalPrice,
      'pacDiscountString': discountString,
      'pacDiscountPercentage': discountPercentage,
      'pacDiscountedPrice': discountedPrice,
      'pacDescription': description,
      'pacProducts': _products,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      setState(() => _isUploading = true);
      if (editingDocId == null) {
        await _supabase.from('userPackages').insert(packageData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ নতুন প্যাকেজ সফলভাবে যোগ করা হয়েছে।')));
      } else {
        await _supabase
            .from('userPackages')
            .update(packageData)
            .eq('id', editingDocId!);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ প্যাকেজ সফলভাবে আপডেট হয়েছে।')));
      }
      clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ ত্রুটি ঘটেছে: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void startEditing(Map<String, dynamic> data) {
    _nameController.text = data['pacName'] ?? '';
    _imageUrlController.text = data['pacImageUrl'] ?? '';
    _totalPriceController.text = data['pacTotalPrice']?.toString() ?? '';
    _discountStringController.text = data['pacDiscountString'] ?? '';
    _discountPercentageController.text =
        data['pacDiscountPercentage']?.toString() ?? '';
    _descriptionController.text = data['pacDescription'] ?? '';
    _products = List<Map<String, dynamic>>.from(data['pacProducts'] ?? []);
    editingDocId = data['id'];
    editingProductIndex = null;
    setState(() {});
  }

  Future<void> deletePackage(String docId, String? imageUrl) async {
    try {
      setState(() => _isUploading = true);

      // Fetch the package document to get product image URLs
      final packageDoc = await _supabase
          .from('userPackages')
          .select()
          .eq('id', docId)
          .single();
      final data = packageDoc;

      // Delete main package image from Supabase Storage if exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final path = imageUrl.substring(imageUrl.indexOf('/o/') + 3);
          await _supabase.storage.from('packages').remove([path]);
        } catch (e) {
          debugPrint(
              'Error deleting main package image from Supabase Storage: $e');
          // Continue with Supabase deletion even if image deletion fails
        }
      }

      // Delete product images from Supabase Storage if they exist
      if (data.containsKey('products')) {
        final products = List<Map<String, dynamic>>.from(data['products']);
        for (var product in products) {
          final productImageUrl = product['imageUrl'] as String?;
          if (productImageUrl != null && productImageUrl.isNotEmpty) {
            try {
              final path =
                  productImageUrl.substring(productImageUrl.indexOf('/o/') + 3);
              await _supabase.storage.from('packages').remove([path]);
            } catch (e) {
              debugPrint(
                  'Error deleting product image from Supabase Storage: $e');
              // Continue with Supabase deletion even if a product image deletion fails
            }
          }
        }
      }

      // Finally, delete the package document from Supabase
      await _supabase.from('userPackages').delete().eq('id', docId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🗑️ প্যাকেজ সফলভাবে মুছে ফেলা হয়েছে।')));
      if (editingDocId == docId) clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ ডিলিটে সমস্যা: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛍️ প্যাকেজ অ্যাডমিন প্যানেল'),
        elevation: 4,
        backgroundColor: theme.primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.colorScheme.surface.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            // পরিবর্তন ১: SingleChildScrollView এর পরিবর্তে ListView ব্যবহার
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editingDocId == null
                              ? 'নতুন প্যাকেজ যোগ করুন'
                              : 'প্যাকেজ সম্পাদনা করুন',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle('প্যাকেজের তথ্য'),
                        _buildTextField(_nameController, 'প্যাকেজের নাম'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                  _imageUrlController, 'ছবির URL'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.image_search),
                              onPressed: _isUploading
                                  ? null
                                  : () => pickImage(_imageUrlController),
                              tooltip: 'ছবি আপলোড করুন',
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    _totalPriceController, 'মোট মূল্য',
                                    keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildTextField(
                                    _discountPercentageController,
                                    'ছাড়ের শতাংশ',
                                    keyboardType: TextInputType.number)),
                          ],
                        ),
                        _buildTextField(
                            _discountStringController, 'ছাড়ের বিবরণ'),
                        _buildTextField(_descriptionController, 'বিবরণ',
                            maxLines: 3),
                        const SizedBox(height: 24),
                        _buildSectionTitle('পণ্যের তালিকা'),
                        _buildProductEntryForm(),
                        const SizedBox(height: 12),
                        if (_products.isNotEmpty) _buildProductList(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : savePackage,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Icon(editingDocId == null
                                    ? Icons.add_circle
                                    : Icons.save),
                            label: Text(editingDocId == null
                                ? 'প্যাকেজ যোগ করুন'
                                : 'আপডেট করুন'),
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        if (editingDocId != null)
                          Center(
                            child: TextButton(
                                onPressed: _isUploading ? null : clearForm,
                                child: const Text('বাতিল করুন')),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase.from('userPackages').stream(
                      primaryKey: ['id']).order('createdAt', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child:
                            Center(child: Text('কোনো প্যাকেজ পাওয়া যায়নি।')),
                      );
                    }
                    final docs = snapshot.data!;
                    return ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const AlwaysScrollableScrollPhysics(), // পরিবর্তন ২: NeverScrollableScrollPhysics এর পরিবর্তে AlwaysScrollableScrollPhysics
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(data['pacImageUrl'] ??
                                'https://via.placeholder.com/150'),
                            radius: 25,
                          ),
                          title: Text(data['pacName'] ?? 'No Name',
                              style: theme.textTheme.titleMedium),
                          subtitle: Text(
                              'মূল্য: ৳${data['pacTotalPrice']?.toStringAsFixed(0) ?? '0'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit,
                                    color: theme.colorScheme.primary),
                                onPressed: () => startEditing(doc),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: theme.colorScheme.error),
                                onPressed: () => _showDeleteDialog(doc),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(context).primaryColor)),
    );
  }

  Widget _buildProductEntryForm() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_productNameController, 'প্রোডাক্ট নাম'),
            Row(
              children: [
                Expanded(
                    child:
                        _buildTextField(_productQuantityController, 'পরিমাণ')),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                      _productUnitPriceController, 'একক মূল্য',
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                      _productImageUrlController, 'প্রোডাক্ট ছবির URL'),
                ),
                IconButton(
                  icon: const Icon(Icons.image_search),
                  onPressed: _isUploading
                      ? null
                      : () => pickImage(_productImageUrlController),
                  tooltip: 'প্রোডাক্টের ছবি আপলোড',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : addOrUpdateProduct,
              icon: Icon(editingProductIndex != null ? Icons.save : Icons.add),
              label: Text(editingProductIndex != null
                  ? 'প্রোডাক্ট আপডেট'
                  : 'প্রোডাক্ট যোগ'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return SizedBox(
      // পরিবর্তন ৩: একটি নির্দিষ্ট উচ্চতা দেওয়া হয়েছে
      height: 200, // আপনি প্রয়োজন অনুযায়ী উচ্চতা পরিবর্তন করতে পারেন
      child: ListView.builder(
        shrinkWrap: true,
        physics:
            const AlwaysScrollableScrollPhysics(), // পরিবর্তন ৪: NeverScrollableScrollPhysics এর পরিবর্তে AlwaysScrollableScrollPhysics
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final p = _products[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Image.network(p['imageUrl'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
              title: Text('${p['name']}'),
              subtitle: Text('${p['quantity']} × ৳${p['unitPrice']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit,
                        color: Theme.of(context).colorScheme.primary),
                    onPressed: () => editProduct(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () => removeProduct(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> doc) {
    final data = doc;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('নিশ্চিত করুন'),
        content: const Text('আপনি কি এই প্যাকেজটি মুছে ফেলতে চান?'),
        actions: [
          TextButton(
              child: const Text('না'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text('হ্যাঁ'),
            onPressed: () {
              Navigator.pop(context);
              deletePackage(doc['id'], data['pacImageUrl']);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (val) => val == null || val.isEmpty ? '$label দিন' : null,
      ),
    );
  }
}
