import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Required for image picking
import 'package:amar_uddokta/uddoktaa/controllers/admin_offer_controller.dart';
import 'package:amar_uddokta/uddoktaa/models/offer_model.dart';
import 'package:intl/intl.dart';

class OfferManagementScreen extends StatefulWidget {
  const OfferManagementScreen({super.key});
  @override
  State<OfferManagementScreen> createState() => _OfferManagementScreenState();
}

class _OfferManagementScreenState extends State<OfferManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminOfferControllerr adminOfferController =
      Get.put(AdminOfferControllerr());
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offer Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'Offers List',
            ),
            Tab(
              icon: Icon(Icons.add),
              text: 'Add Offer',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOffersList(),
          OfferFormContent(adminOfferController: adminOfferController),
        ],
      ),
    );
  }

  Widget _buildOffersList() {
    return Obx(() {
      if (adminOfferController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (adminOfferController.offers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined,
                  size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No offers available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first offer to get started',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: adminOfferController.offers.length,
        itemBuilder: (context, index) {
          final offer = adminOfferController.offers[index];
          return _buildOfferCard(offer, context);
        },
      );
    });
  }

  Widget _buildOfferCard(Offer offer, BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final discountedPrice =
        offer.originalPrice * (1 - (offer.discountPercentage / 100));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shadowColor: Colors.deepPurple.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Show offer details
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image container with shadow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: offer.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[300],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offer name
                      Text(
                        offer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepPurple,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Company name with icon
                      Row(
                        children: [
                          Icon(Icons.business,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              offer.company,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Price information
                      Row(
                        children: [
                          // Discounted price
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '৳${discountedPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Original price with strikethrough
                          Flexible(
                            child: Text(
                              '৳${offer.originalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Discount percentage tag
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${offer.discountPercentage}% off',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stock status
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 16,
                            color:
                                offer.stock > 10 ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${offer.stock}',
                            style: TextStyle(
                              color: offer.stock > 10
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // End time
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Ends: ${dateFormat.format(offer.endTime)}',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Action buttons
                      Row(
                        children: [
                          // Active/Inactive status
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    offer.isActive ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    offer.isActive
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      offer.isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Edit button
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                adminOfferController
                                    .selectedOfferForEdit.value = offer;
                                _tabController.animateTo(1);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                _showDeleteDialog(offer, context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Offer offer, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirm Delete',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Are you sure you want to delete "${offer.name}"? This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await adminOfferController.deleteOffer(offer.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OfferFormContent extends StatefulWidget {
  final AdminOfferControllerr adminOfferController;
  const OfferFormContent({
    super.key,
    required this.adminOfferController,
  });
  @override
  State<OfferFormContent> createState() => _OfferFormContentState();
}

class _OfferFormContentState extends State<OfferFormContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _detailsController;
  late TextEditingController _imageUrlController;
  File? _pickedImage; // Variable to store the picked image file
  late TextEditingController _companyController;
  late TextEditingController _originalPriceController;
  late TextEditingController _unitController;
  late TextEditingController _discountPercentageController;
  late TextEditingController _stockController;
  late TextEditingController _colorsController;
  late TextEditingController _sizeController;
  late TextEditingController _categoryController;
  late TextEditingController _subItemNameController;
  late RxBool _isActive;
  late Rx<DateTime> _endTime;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _detailsController = TextEditingController();
    _imageUrlController = TextEditingController();
    _companyController = TextEditingController();
    _originalPriceController = TextEditingController();
    _unitController = TextEditingController();
    _discountPercentageController = TextEditingController();
    _stockController = TextEditingController();
    _colorsController = TextEditingController();
    _sizeController = TextEditingController();
    _categoryController = TextEditingController();
    _subItemNameController = TextEditingController();
    _isActive = false.obs;
    _endTime = DateTime.now().add(const Duration(days: 7)).obs;
    _listenToSelectedOffer();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void didUpdateWidget(covariant OfferFormContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adminOfferController != oldWidget.adminOfferController) {
      _listenToSelectedOffer();
    }
  }

  void _listenToSelectedOffer() {
    ever(widget.adminOfferController.selectedOfferForEdit, (Offer? offer) {
      _populateForm(offer);
    });
    _populateForm(widget.adminOfferController.selectedOfferForEdit.value);
  }

  void _populateForm(Offer? offer) {
    _nameController.text = offer?.name ?? '';
    _detailsController.text = offer?.details ?? '';
    _imageUrlController.text = offer?.imageUrl ?? '';
    _pickedImage =
        null; // Clear picked image when populating form for existing offer
    _companyController.text = offer?.company ?? '';
    _originalPriceController.text = offer?.originalPrice.toString() ?? '';
    _unitController.text = offer?.unit ?? '';
    _discountPercentageController.text =
        offer?.discountPercentage.toString() ?? '';
    _stockController.text = offer?.stock.toString() ?? '';
    _colorsController.text = offer?.colors.join(', ') ?? '';
    _sizeController.text = offer?.size.join(', ') ?? '';
    _categoryController.text = offer?.category ?? '';
    _subItemNameController.text = offer?.subItemName ?? '';
    _isActive.value = offer?.isActive ?? false;

    // তারিখ সঠিকভাবে সেট করা
    if (offer != null) {
      _endTime.value = offer.endTime;
    } else {
      _endTime.value = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _imageUrlController.dispose();
    _companyController.dispose();
    _originalPriceController.dispose();
    _unitController.dispose();
    _discountPercentageController.dispose();
    _stockController.dispose();
    _colorsController.dispose();
    _sizeController.dispose();
    _categoryController.dispose();
    _subItemNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endTime.value,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime.value),
      );

      if (pickedTime != null) {
        setState(() {
          _endTime.value = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _endTime.value = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _endTime.value.hour,
            _endTime.value.minute,
          );
        });
      }
    }
  }

  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      final fileName =
          'offers/${DateTime.now().millisecondsSinceEpoch.toString()}';
      await Supabase.instance.client.storage
          .from('offers')
          .upload(fileName, imageFile);
      final downloadUrl = Supabase.instance.client.storage
          .from('offers')
          .getPublicUrl(fileName);
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Supabase Storage: $e');
      Get.snackbar('Error', 'Failed to upload image: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
      return null;
    }
  }

  Future<void> _saveOffer() async {
    print('Validating form...');
    if (_formKey.currentState!.validate()) {
      print('Form is valid. Creating Offer object...');

      String? imageUrl = _imageUrlController.text;
      if (_pickedImage != null) {
        print('Uploading new image...');
        imageUrl = await _uploadImageToSupabase(_pickedImage!);
        if (imageUrl == null) {
          print('Image upload failed. Aborting save.');
          return; // Abort if image upload fails
        }
        print('Image uploaded. URL: $imageUrl');
      } else if (imageUrl.isEmpty) {
        Get.snackbar('Error', 'Please pick an image or provide an Image URL',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
        return;
      }

      final newOffer = Offer(
        id: widget.adminOfferController.selectedOfferForEdit.value == null
            ? ''
            : widget.adminOfferController.selectedOfferForEdit.value!.id,
        name: _nameController.text,
        details: _detailsController.text,
        imageUrl: imageUrl, // Use the uploaded URL or existing URL
        company: _companyController.text,
        originalPrice: double.parse(_originalPriceController.text),
        unit: _unitController.text,
        discountPercentage: double.parse(_discountPercentageController.text),
        stock: int.parse(_stockController.text),
        colors: _colorsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        size: _sizeController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        category: _categoryController.text,
        subItemName: _subItemNameController.text,
        isActive: _isActive.value,
        endTime: _endTime.value,
      );

      if (widget.adminOfferController.selectedOfferForEdit.value == null) {
        print('Calling addOffer...');
        await widget.adminOfferController.addOffer(newOffer);
        print('addOffer called.');
      } else {
        print('Calling updateOffer...');
        await widget.adminOfferController.updateOffer(newOffer);
        print('updateOffer called.');
      }

      print('Resetting form and clearing selected offer...');
      _formKey.currentState?.reset();
      _isActive.value = false;
      _endTime.value = DateTime.now().add(const Duration(days: 7));
      _pickedImage = null; // Clear picked image after saving
      widget.adminOfferController.clearSelectedOffer();
      print('Form reset and selected offer cleared.');
    } else {
      print('Form validation failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Image card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: _pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _pickedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (_imageUrlController.text.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: _imageUrlController.text,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.deepPurple,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap to select offer image',
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'JPG, PNG recommended',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image URL (if not uploading new image)',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.url,
                      readOnly: _pickedImage != null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Basic Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Offer Name',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an offer name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _detailsController,
                      decoration: InputDecoration(
                        labelText: 'Details',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter offer details';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: 'Company',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pricing Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pricing Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _originalPriceController,
                      decoration: InputDecoration(
                        labelText: 'Original Price',
                        prefixIcon: const Icon(Icons.money),
                        prefixText: '৳ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _discountPercentageController,
                      decoration: InputDecoration(
                        labelText: 'Discount Percentage',
                        prefixIcon: const Icon(Icons.percent),
                        suffixText: '%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(
                        labelText: 'Stock',
                        prefixIcon: const Icon(Icons.inventory),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Please enter a valid integer';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        prefixIcon: const Icon(Icons.straighten),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _colorsController,
                      decoration: InputDecoration(
                        labelText: 'Colors (comma-separated)',
                        prefixIcon: const Icon(Icons.palette),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sizeController,
                      decoration: InputDecoration(
                        labelText: 'Sizes (comma-separated)',
                        prefixIcon: const Icon(Icons.aspect_ratio),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subItemNameController,
                      decoration: InputDecoration(
                        labelText: 'Sub Item Name',
                        prefixIcon: const Icon(Icons.subdirectory_arrow_right),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Offer Settings Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Active/Inactive Switch
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Obx(() => Row(
                            children: [
                              Icon(
                                _isActive.value
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color:
                                    _isActive.value ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Is Active',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isActive.value,
                                onChanged: (bool value) {
                                  _isActive.value = value;
                                },
                                activeThumbColor: Colors.deepPurple,
                              ),
                            ],
                          )),
                    ),
                    const SizedBox(height: 16),
                    // End Date Picker
                    Obx(() => InkWell(
                          onTap: () => _selectDateTime(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Date & Time',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy - hh:mm a')
                                            .format(_endTime.value),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.adminOfferController
                                        .selectedOfferForEdit.value !=
                                    null)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                ),
                child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.adminOfferController.selectedOfferForEdit
                                      .value ==
                                  null
                              ? Icons.add_circle
                              : Icons.edit,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.adminOfferController.selectedOfferForEdit
                                      .value ==
                                  null
                              ? 'Add Offer'
                              : 'Update Offer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
