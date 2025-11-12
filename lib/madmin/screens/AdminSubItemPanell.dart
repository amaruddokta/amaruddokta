import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:get/get.dart';
import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSubItemPanel extends StatefulWidget {
  final String categoryName;
  final String searchQuery;

  const AdminSubItemPanel({
    super.key,
    this.categoryName = '',
    this.searchQuery = '',
  });

  @override
  State<AdminSubItemPanel> createState() => _AdminSubItemPanelState();
}

class _AdminSubItemPanelState extends State<AdminSubItemPanel>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'ponno';

  // Text controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController subItemController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController detailsController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  TextEditingController stockController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  TextEditingController colorController = TextEditingController();
  TextEditingController sizeController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  TextEditingController imageUrlController = TextEditingController();
  TextEditingController videoUrlController = TextEditingController();

  String selectedAddCategory = "";
  String imageUrl = '';
  String videoUrl = '';
  bool _isUploading = false;
  bool _isExpanded = false;

  final List<Map<String, TextEditingController>> _sizePriceUnitList = [];
  bool _hasSizes = false;

  late Future<List<Map<String, dynamic>>> _futureProducts;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetchProducts();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant AdminSubItemPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.categoryName != widget.categoryName) {
      _futureProducts = _fetchProducts();
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    nameController.dispose();
    subItemController.dispose();
    unitController.dispose();
    detailsController.dispose();
    priceController.dispose();
    discountController.dispose();
    stockController.dispose();
    companyController.dispose();
    colorController.dispose();
    sizeController.dispose();
    searchController.dispose();
    imageUrlController.dispose();
    videoUrlController.dispose();
    for (var entry in _sizePriceUnitList) {
      entry['size']?.dispose();
      entry['price']?.dispose();
      entry['unit']?.dispose();
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final response = await _supabase.from('ponno').select('''
            *,
            categories (
              categories_name
            )
          ''');
      final allProducts = List<Map<String, dynamic>>.from(response);

      final filteredProducts = allProducts.where((product) {
        final matchesCategory = widget.categoryName.isEmpty ||
            (product['categories']?['categories_name'] ?? '')
                    .toString()
                    .trim() ==
                widget.categoryName.trim();

        final matchesSearch = (product['usernames'] ?? '')
            .toString()
            .toLowerCase()
            .contains(widget.searchQuery.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();

      return filteredProducts;
    } catch (e) {
      debugPrint('পণ্য লোড করতে সমস্যা: $e');
      return [];
    }
  }

  void _addSizePriceUnitField({String? size, String? price, String? unit}) {
    setState(() {
      _sizePriceUnitList.add({
        'size': TextEditingController(text: size),
        'price': TextEditingController(text: price),
        'unit': TextEditingController(text: unit),
      });
    });
  }

  void _removeSizePriceUnitField(int index) {
    setState(() {
      _sizePriceUnitList[index]['size']?.dispose();
      _sizePriceUnitList[index]['price']?.dispose();
      _sizePriceUnitList[index]['unit']?.dispose();
      _sizePriceUnitList.removeAt(index);
      _updateMainPriceUnitFromSizes();
    });
  }

  void _updateMainPriceUnitFromSizes() {
    if (!_hasSizes || _sizePriceUnitList.isEmpty) {
      priceController.clear();
      unitController.clear();
      return;
    }

    Map<String, TextEditingController>? smallestSizeEntry;
    double? smallestSizeValue;

    for (var entry in _sizePriceUnitList) {
      final sizeText = entry['size']?.text;
      if (sizeText != null && sizeText.isNotEmpty) {
        try {
          final currentSizeValue = double.parse(sizeText);
          if (smallestSizeEntry == null ||
              currentSizeValue < smallestSizeValue!) {
            smallestSizeValue = currentSizeValue;
            smallestSizeEntry = entry;
          }
        } catch (e) {
          debugPrint('Error parsing size: $e');
        }
      }
    }

    if (smallestSizeEntry != null) {
      priceController.text = smallestSizeEntry['price']?.text ?? '';
      unitController.text = smallestSizeEntry['unit']?.text ?? '';
    } else {
      priceController.clear();
      unitController.clear();
    }
  }

  Future<String?> _uploadFileToSupabase(
    Uint8List fileBytes,
    String fileName,
    String fileExtension,
    bool isVideo,
  ) async {
    try {
      final String filePath = '$_bucketName/$fileName';
      await _supabase.storage.from(_bucketName).uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType:
                  isVideo ? 'video/$fileExtension' : 'image/$fileExtension',
            ),
          );
      return _supabase.storage.from(_bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Supabase Storage Upload error: $e');
      return null;
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isUploading = true);

        final compressedBytes = await FlutterImageCompress.compressWithFile(
          pickedFile.path,
          minWidth: 1000,
          minHeight: 1000,
          quality: 85,
        );

        if (compressedBytes == null) {
          _showCustomSnackBar('❌ ইমেজ কম্প্রেস ব্যর্থ হয়েছে', Colors.red);
          return;
        }

        String fileExtension =
            path.extension(pickedFile.path).replaceAll('.', '');
        if (fileExtension.isEmpty) fileExtension = 'jpg';
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final uploadedUrl = await _uploadFileToSupabase(
          Uint8List.fromList(compressedBytes),
          fileName,
          fileExtension,
          false,
        );

        if (uploadedUrl != null) {
          setState(() {
            imageUrl = uploadedUrl;
            imageUrlController.text = uploadedUrl;
          });
          _showCustomSnackBar('✅ ইমেজ সফলভাবে আপলোড হয়েছে', Colors.green);
        } else {
          _showCustomSnackBar('❌ ইমেজ আপলোড ব্যর্থ হয়েছে', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      _showCustomSnackBar('❌ ত্রুটি: $e', Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);

        final file = result.files.single;
        final String? filePath = file.path;

        if (filePath == null) {
          _showCustomSnackBar('❌ ভিডিও ফাইল পাথ পাওয়া যায়নি', Colors.red);
          return;
        }

        final mediaInfo = await VideoCompress.compressVideo(
          filePath,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );

        if (mediaInfo == null || mediaInfo.file == null) {
          _showCustomSnackBar('❌ ভিডিও কম্প্রেস ব্যর্থ হয়েছে', Colors.red);
          return;
        }

        final compressedVideoBytes = await mediaInfo.file!.readAsBytes();
        String fileExtension = path.extension(file.name).replaceAll('.', '');
        if (fileExtension.isEmpty) fileExtension = 'mp4';
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final uploadedUrl = await _uploadFileToSupabase(
          compressedVideoBytes,
          fileName,
          fileExtension,
          true,
        );

        if (uploadedUrl != null) {
          setState(() {
            videoUrl = uploadedUrl;
            videoUrlController.text = uploadedUrl;
          });
          _showCustomSnackBar('✅ ভিডিও সফলভাবে আপলোড হয়েছে', Colors.green);
        } else {
          _showCustomSnackBar('❌ ভিডিও আপলোড ব্যর্থ হয়েছে', Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Video pick error: $e');
      _showCustomSnackBar('❌ ত্রুটি: $e', Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> deleteProduct(
    String docId,
    String? imageUrl,
    String? videoUrl,
  ) async {
    try {
      setState(() => _isUploading = true);

      Future<void> deleteFileFromStorage(String? url) async {
        if (url != null && url.isNotEmpty) {
          try {
            final uri = Uri.parse(url);
            final pathSegments = uri.pathSegments;
            final bucketIndex = pathSegments.indexOf(_bucketName);
            if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
              final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
              await _supabase.storage.from(_bucketName).remove([filePath]);
            }
          } catch (e) {
            debugPrint('Failed to delete file from storage: $e');
          }
        }
      }

      await deleteFileFromStorage(imageUrl);
      await deleteFileFromStorage(videoUrl);

      await _supabase.from('ponno').delete().eq('id', docId);

      _showCustomSnackBar('🗑️ প্রোডাক্ট ডিলিট করা হয়েছে', Colors.green);
    } catch (e) {
      _showCustomSnackBar('❌ ডিলিট করতে সমস্যা: $e', Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void showEditDialog(String docId, Map<String, dynamic> data) {
    nameController.text = data['usernames'] ?? '';
    subItemController.text = data['userItem'] ?? '';
    detailsController.text = data['userdetailss'] ?? '';
    discountController.text = (data['userdiscounts'] ?? '').toString();
    stockController.text = (data['userstocks'] ?? '').toString();
    companyController.text = data['userscompanys'] ?? '';
    colorController.text = data['usercolors'] ?? '';
    selectedAddCategory = data['UCategorys'] ?? '';
    imageUrl = data['userimageUrls'] ?? '';
    videoUrl = data['uservideoUrls'] ?? '';
    imageUrlController.text = imageUrl;
    videoUrlController.text = videoUrl;

    for (var entry in _sizePriceUnitList) {
      entry['size']?.dispose();
      entry['price']?.dispose();
      entry['unit']?.dispose();
    }
    _sizePriceUnitList.clear();

    final List<dynamic>? sizesData = data['sizes'] as List<dynamic>?;
    if (sizesData != null && sizesData.isNotEmpty) {
      _hasSizes = true;
      for (var sizeEntry in sizesData) {
        _addSizePriceUnitField(
          size: sizeEntry['size']?.toString(),
          price: sizeEntry['price']?.toString(),
          unit: sizeEntry['unit']?.toString(),
        );
      }
      _updateMainPriceUnitFromSizes();
    } else {
      _hasSizes = false;
      priceController.text = (data['price'] ?? '').toString();
      unitController.text = data['unit'] ?? '';
      sizeController.text = data['size'] ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 10,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '✏️ প্রোডাক্ট এডিট করুন',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTextField(nameController, 'নাম'),
                          const SizedBox(height: 10),
                          _buildTextField(subItemController, 'সাব-আইটেম'),
                          const SizedBox(height: 10),
                          _buildTextField(detailsController, 'বিস্তারিত',
                              maxLines: 3),
                          const SizedBox(height: 10),
                          _buildNumberTextField(
                              discountController, 'ডিসকাউন্ট'),
                          const SizedBox(height: 10),
                          _buildNumberTextField(stockController, 'স্টক'),
                          const SizedBox(height: 10),
                          _buildTextField(companyController, 'কোম্পানি'),
                          const SizedBox(height: 10),
                          _buildTextField(colorController, 'রং'),
                          const SizedBox(height: 10),

                          // Category dropdown
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _supabase
                                .from('categories')
                                .select('id, categories_name'),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              if (snapshot.hasError) {
                                return const Text('Something went wrong');
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text('No categories found');
                              }
                              final categories = snapshot.data!;
                              return DropdownButtonFormField<String>(
                                value: selectedAddCategory.isNotEmpty
                                    ? selectedAddCategory
                                    : null,
                                items: categories.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category['id'].toString(),
                                    child: Text(category['categories_name']),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setStateDialog(() {
                                    selectedAddCategory = newValue!;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'ক্যাটাগরি',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),

                          // Size options
                          CheckboxListTile(
                            title: const Text('সাইজ অনুযায়ী দাম ও ইউনিট'),
                            value: _hasSizes,
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                _hasSizes = value ?? false;
                                if (_hasSizes) {
                                  priceController.clear();
                                  unitController.clear();
                                  sizeController.clear();
                                  if (_sizePriceUnitList.isEmpty) {
                                    _addSizePriceUnitField();
                                  }
                                } else {
                                  for (var entry in _sizePriceUnitList) {
                                    entry['size']?.dispose();
                                    entry['price']?.dispose();
                                    entry['unit']?.dispose();
                                  }
                                  _sizePriceUnitList.clear();
                                }
                                _updateMainPriceUnitFromSizes();
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),

                          if (_hasSizes) ...[
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _sizePriceUnitList.length,
                              itemBuilder: (context, index) {
                                final entry = _sizePriceUnitList[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          entry['size']!,
                                          'সাইজ ${index + 1}',
                                          onChanged: (_) => setStateDialog(() =>
                                              _updateMainPriceUnitFromSizes()),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildNumberTextField(
                                          entry['price']!,
                                          'দাম ${index + 1}',
                                          onChanged: (_) => setStateDialog(() =>
                                              _updateMainPriceUnitFromSizes()),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildTextField(
                                          entry['unit']!,
                                          'ইউনিট ${index + 1}',
                                          onChanged: (_) => setStateDialog(() =>
                                              _updateMainPriceUnitFromSizes()),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: () {
                                          setStateDialog(() {
                                            _removeSizePriceUnitField(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.green),
                                onPressed: () {
                                  setStateDialog(() {
                                    _addSizePriceUnitField();
                                  });
                                },
                              ),
                            ),
                          ] else ...[
                            _buildNumberTextField(priceController, 'দাম'),
                            const SizedBox(height: 10),
                            _buildTextField(unitController, 'ইউনিট'),
                            const SizedBox(height: 10),
                            _buildTextField(sizeController, 'সাইজ'),
                            const SizedBox(height: 10),
                          ],

                          // Image section
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text('ছবি সিলেক্ট করুন'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(imageUrl,
                                      width: 50, height: 50, fit: BoxFit.cover),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(imageUrlController, 'ছবি URL'),
                          const SizedBox(height: 10),

                          // Video section
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: pickVideo,
                                icon: const Icon(Icons.video_library),
                                label: const Text('ভিডিও সিলেক্ট করুন'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (videoUrl.isNotEmpty)
                                const Icon(Icons.video_file, color: Colors.red),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(videoUrlController, 'ভিডিও URL'),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('বাতিল করুন'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              setState(() => _isUploading = true);

                              final Map<String, dynamic> updateData = {
                                'usernames': nameController.text,
                                'userItem': subItemController.text,
                                'userdetailss': detailsController.text,
                                'userdiscounts':
                                    int.tryParse(discountController.text) ?? 0,
                                'userstocks':
                                    int.tryParse(stockController.text) ?? 0,
                                'userscompanys': companyController.text,
                                'usercolors': colorController.text,
                                'UCategorys': selectedAddCategory,
                                'userimageUrls': imageUrlController.text,
                                'uservideoUrls': videoUrlController.text,
                              };

                              if (_hasSizes) {
                                updateData['sizes'] = _sizePriceUnitList
                                    .map((entry) => {
                                          'size': entry['size']?.text,
                                          'price': double.tryParse(
                                                  entry['price']?.text ?? '') ??
                                              0,
                                          'unit': entry['unit']?.text,
                                        })
                                    .toList();
                                updateData['price'] = null;
                                updateData['unit'] = null;
                                updateData['size'] = null;
                              } else {
                                updateData['price'] =
                                    double.tryParse(priceController.text) ?? 0;
                                updateData['unit'] = unitController.text;
                                updateData['size'] = sizeController.text;
                                updateData['sizes'] = null;
                              }

                              await _supabase
                                  .from('ponno')
                                  .update(updateData)
                                  .eq('id', docId);

                              Navigator.pop(context);
                              setState(() {
                                _futureProducts = _fetchProducts();
                              });
                              _showCustomSnackBar(
                                  '✅ প্রোডাক্ট আপডেট করা হয়েছে', Colors.green);
                            } catch (e) {
                              _showCustomSnackBar(
                                  '❌ আপডেট করতে সমস্যা: $e', Colors.red);
                            } finally {
                              setState(() => _isUploading = false);
                            }
                          },
                          child: const Text('আপডেট করুন'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberTextField(TextEditingController controller, String label,
      {Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('🛒 অ্যাডমিন সাব-আইটেম প্যানেল'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                  _isExpanded
                      ? _fabAnimationController.forward()
                      : _fabAnimationController.reverse();
                });
              },
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add product section
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isExpanded ? null : 0,
                  child: _isExpanded
                      ? _buildAddProductSection()
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 12),

                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'নাম দিয়ে খুঁজুন',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onChanged: (_) => setState(() {
                      _futureProducts = _fetchProducts();
                    }),
                  ),
                ),

                const SizedBox(height: 12),

                // Products list
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _futureProducts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator();
                    } else if (snapshot.hasError) {
                      return _buildErrorWidget(snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyWidget();
                    }

                    return _buildProductGrid(snapshot.data!);
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
              _isExpanded
                  ? _fabAnimationController.forward()
                  : _fabAnimationController.reverse();
            });
          },
          backgroundColor: Theme.of(context).primaryColor,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabAnimationController,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAddProductSection() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'নতুন সাব-আইটেম যুক্ত করুন',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isExpanded = false;
                      _fabAnimationController.reverse();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category dropdown
            FutureBuilder<List<Map<String, dynamic>>>(
              future:
                  _supabase.from('categories').select('id, categories_name'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No categories found');
                }
                final categories = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: selectedAddCategory.isNotEmpty
                      ? selectedAddCategory
                      : null,
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'].toString(),
                      child: Text(category['categories_name']),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAddCategory = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'ক্যাটাগরি',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildTextField(nameController, 'নাম'),
            const SizedBox(height: 10),
            _buildTextField(subItemController, 'সাব-আইটেম'),
            const SizedBox(height: 10),
            _buildTextField(detailsController, 'বিস্তারিত', maxLines: 3),
            const SizedBox(height: 10),
            _buildNumberTextField(discountController, 'ডিসকাউন্ট'),
            const SizedBox(height: 10),
            _buildNumberTextField(stockController, 'স্টক'),
            const SizedBox(height: 10),
            _buildTextField(companyController, 'কোম্পানি'),
            const SizedBox(height: 10),
            _buildTextField(colorController, 'রং'),
            const SizedBox(height: 10),

            // Size options
            CheckboxListTile(
              title: const Text('সাইজ অনুযায়ী দাম ও ইউনিট'),
              value: _hasSizes,
              onChanged: (bool? value) {
                setState(() {
                  _hasSizes = value ?? false;
                  if (_hasSizes) {
                    priceController.clear();
                    unitController.clear();
                    sizeController.clear();
                    if (_sizePriceUnitList.isEmpty) {
                      _addSizePriceUnitField();
                    }
                  } else {
                    for (var entry in _sizePriceUnitList) {
                      entry['size']?.dispose();
                      entry['price']?.dispose();
                      entry['unit']?.dispose();
                    }
                    _sizePriceUnitList.clear();
                  }
                  _updateMainPriceUnitFromSizes();
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),

            if (_hasSizes) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sizePriceUnitList.length,
                itemBuilder: (context, index) {
                  final entry = _sizePriceUnitList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            entry['size']!,
                            'সাইজ ${index + 1}',
                            onChanged: (_) =>
                                setState(() => _updateMainPriceUnitFromSizes()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNumberTextField(
                            entry['price']!,
                            'দাম ${index + 1}',
                            onChanged: (_) =>
                                setState(() => _updateMainPriceUnitFromSizes()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            entry['unit']!,
                            'ইউনিট ${index + 1}',
                            onChanged: (_) =>
                                setState(() => _updateMainPriceUnitFromSizes()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _removeSizePriceUnitField(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      _addSizePriceUnitField();
                    });
                  },
                ),
              ),
            ] else ...[
              _buildNumberTextField(priceController, 'দাম'),
              const SizedBox(height: 10),
              _buildTextField(unitController, 'ইউনিট'),
              const SizedBox(height: 10),
              _buildTextField(sizeController, 'সাইজ'),
              const SizedBox(height: 10),
            ],

            // Image section
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('ছবি সিলেক্ট করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl,
                        width: 50, height: 50, fit: BoxFit.cover),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField(imageUrlController, 'ছবি URL'),
            const SizedBox(height: 10),

            // Video section
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text('ভিডিও সিলেক্ট করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                if (videoUrl.isNotEmpty)
                  const Icon(Icons.video_file, color: Colors.red),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField(videoUrlController, 'ভিডিও URL'),
            const SizedBox(height: 16),

            // Add product button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isUploading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Icon(Icons.add),
                label: const Text("প্রোডাক্ট যোগ করুন"),
                onPressed: _isUploading
                    ? null
                    : () async {
                        if (selectedAddCategory.isEmpty ||
                            nameController.text.isEmpty) {
                          _showCustomSnackBar(
                              '⚠️ সব ফিল্ড পূরণ করুন', Colors.orange);
                          return;
                        }

                        try {
                          setState(() => _isUploading = true);

                          final Map<String, dynamic> addData = {
                            'usernames': nameController.text.trim(),
                            'userItem': subItemController.text.trim(),
                            'userdetailss': detailsController.text.trim(),
                            'userdiscounts': int.tryParse(
                                  discountController.text.trim(),
                                ) ??
                                0,
                            'userstocks': int.tryParse(
                                  stockController.text.trim(),
                                ) ??
                                0,
                            'userscompanys': companyController.text.trim(),
                            'usercolors': colorController.text.trim(),
                            'UCategorys': selectedAddCategory,
                            'userimageUrls': imageUrlController.text,
                            'uservideoUrls': videoUrlController.text,
                            'createdAt': DateTime.now().toIso8601String(),
                          };

                          if (_hasSizes) {
                            addData['sizes'] = _sizePriceUnitList
                                .map((entry) => {
                                      'size': entry['size']?.text,
                                      'price': double.tryParse(
                                              entry['price']?.text ?? '') ??
                                          0,
                                      'unit': entry['unit']?.text,
                                    })
                                .toList();
                          } else {
                            addData['price'] =
                                double.tryParse(priceController.text.trim()) ??
                                    0;
                            addData['unit'] = unitController.text.trim();
                            addData['size'] = sizeController.text.trim();
                          }

                          await _supabase.from('ponno').insert(addData);

                          // Clear form
                          nameController.clear();
                          subItemController.clear();
                          unitController.clear();
                          detailsController.clear();
                          priceController.clear();
                          discountController.clear();
                          stockController.clear();
                          companyController.clear();
                          colorController.clear();
                          sizeController.clear();
                          setState(() {
                            imageUrl = '';
                            videoUrl = '';
                            selectedAddCategory = '';
                            _sizePriceUnitList.clear();
                            _hasSizes = false;
                          });
                          imageUrlController.clear();
                          videoUrlController.clear();
                          setState(() {
                            _futureProducts = _fetchProducts();
                          });

                          _showCustomSnackBar(
                              '✅ প্রোডাক্ট সফলভাবে যোগ করা হয়েছে',
                              Colors.green);
                        } catch (e) {
                          _showCustomSnackBar('❌ ত্রুটি: $e', Colors.red);
                        } finally {
                          setState(() => _isUploading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 10),
            Text('ত্রুটি: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text('কোনো প্রোডাক্ট পাওয়া যায়নি'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    final groupedProducts = _groupProductsBySubItem(products);

    return Column(
      children: groupedProducts.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubItemHeader(entry.key),
            _buildAdminProductsGrid(entry.value),
          ],
        );
      }).toList(),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupProductsBySubItem(
      List<Map<String, dynamic>> products) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var product in products) {
      final subItem = (product['userItem'] ?? 'Others').toString();
      grouped.putIfAbsent(subItem, () => []).add(product);
    }
    return grouped;
  }

  Widget _buildSubItemHeader(String subItemName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        subItemName,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildAdminProductsGrid(List<Map<String, dynamic>> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildAdminProductCard(products[index]);
      },
    );
  }

  Map<String, dynamic> _getFirstSizePriceUnit(List<dynamic>? sizesData) {
    if (sizesData == null || sizesData.isEmpty) {
      return {};
    }
    return sizesData.first as Map<String, dynamic>;
  }

  Widget _buildAdminProductCard(Map<String, dynamic> product) {
    final docId = product['id'] ?? '';
    final name = product['usernames'] ?? 'Unknown';
    double displayPrice = (product['price'] ?? 0).toDouble();
    String displayUnit = product['unit'] ?? '';
    final discount = (product['userdiscounts'] ?? 0).toInt();
    final imageUrl = product['userimageUrls'] ?? '';
    final company = product['userscompanys'] ?? 'Unknown';
    final details = product['userdetailss'] ?? '';
    final stock = (product['userstocks'] ?? 0).toInt();
    final subItemName = (product['userItem'] ?? 'Others').toString();
    final category =
        product['categories']?['categories_name'] ?? widget.categoryName;
    final videoUrl = product['uservideoUrls'] ?? '';

    final List<dynamic>? sizesData = product['sizes'] as List<dynamic>?;
    if (sizesData != null && sizesData.isNotEmpty) {
      final firstSizeDetails = _getFirstSizePriceUnit(sizesData);
      if (firstSizeDetails.isNotEmpty) {
        displayPrice = (firstSizeDetails['price'] ?? 0).toDouble();
        displayUnit = firstSizeDetails['unit'] ?? '';
      }
    }

    final discountedPrice =
        (displayPrice * (100 - discount) / 100).toStringAsFixed(2);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product image with discount badge and stock indicator
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Container(
                    color: Colors.grey[200],
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              size: 40, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (stock == 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'স্টক শেষ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Product details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '৳$discountedPrice',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (discount > 0)
                        Text(
                          '৳${displayPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('এডিট',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () => showEditDialog(docId, product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('ডিলিট',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('ডিলিট নিশ্চিত করুন'),
                                content: const Text(
                                  'আপনি কি এই প্রোডাক্টটি ডিলিট করতে চান? এই অ্যাকশনটি পূর্বাবস্থায় ফেরানো যাবে না।',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('বাতিল করুন'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await deleteProduct(
                                          docId, imageUrl, videoUrl);
                                      setState(() {
                                        _futureProducts = _fetchProducts();
                                      });
                                    },
                                    child: const Text('ডিলিট করুন'),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
