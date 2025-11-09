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

class _AdminSubItemPanelState extends State<AdminSubItemPanel> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'ponno';

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

  String selectedAddCategory = ""; // This will now store the UUID
  String imageUrl = '';
  String videoUrl = '';
  bool _isUploading = false;

  List<Map<String, TextEditingController>> _sizePriceUnitList = [];
  bool _hasSizes = false;

  late Future<List<Map<String, dynamic>>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetchProducts();
  }

  @override
  void didUpdateWidget(covariant AdminSubItemPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.categoryName != widget.categoryName) {
      _futureProducts = _fetchProducts();
    }
  }

  // UPDATED: Now fetches category name using a JOIN
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
        // UPDATED: Access category name from the nested 'categories' object
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ইমেজ কম্প্রেস ব্যর্থ হয়েছে')),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ত্রুটি: $e')),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ভিডিও ফাইল পাথ পাওয়া যায়নি')),
          );
          return;
        }

        final mediaInfo = await VideoCompress.compressVideo(
          filePath,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );

        if (mediaInfo == null || mediaInfo.file == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ভিডিও কম্প্রেস ব্যর্থ হয়েছে')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ ভিডিও সফলভাবে আপলোড হয়েছে')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ভিডিও আপলোড ব্যর্থ হয়েছে')),
          );
        }
      }
    } catch (e) {
      debugPrint('Video pick error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ত্রুটি: $e')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ প্রোডাক্ট ডিলিট করা হয়েছে')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ডিলিট করতে সমস্যা: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void showEditDialog(String docId, Map<String, dynamic> data) {
    nameController.text = data['usernames'] ?? '';
    subItemController.text = data['userItem'] ?? '';
    detailsController.text = data['userdetailss'] ?? '';
    discountController.text = (data['userdiscounts'] ?? '').toString();
    stockController.text = (data['userstocks'] ?? '').toString();
    companyController.text = data['userscompanys'] ?? '';
    colorController.text = data['usercolors'] ?? '';
    // UPDATED: Now correctly sets the UUID from the data
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
          return AlertDialog(
            title: const Text('✏️ প্রোডাক্ট এডিট করুন'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'নাম'),
                  ),
                  TextField(
                    controller: subItemController,
                    decoration: const InputDecoration(labelText: 'সাব-আইটেম'),
                  ),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(labelText: 'বিস্তারিত'),
                  ),
                  TextField(
                    controller: discountController,
                    decoration: const InputDecoration(labelText: 'ডিসকাউন্ট'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(labelText: 'স্টক'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(labelText: 'কোম্পানি'),
                  ),
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(labelText: 'রং'),
                  ),
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
                  ),
                  if (_hasSizes) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sizePriceUnitList.length,
                      itemBuilder: (context, index) {
                        final entry = _sizePriceUnitList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: entry['size'],
                                  decoration: InputDecoration(
                                    labelText: 'সাইজ ${index + 1}',
                                  ),
                                  onChanged: (_) => setStateDialog(
                                      () => _updateMainPriceUnitFromSizes()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: entry['price'],
                                  decoration: InputDecoration(
                                    labelText: 'দাম ${index + 1}',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setStateDialog(
                                      () => _updateMainPriceUnitFromSizes()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: entry['unit'],
                                  decoration: InputDecoration(
                                    labelText: 'ইউনিট ${index + 1}',
                                  ),
                                  onChanged: (_) => setStateDialog(
                                      () => _updateMainPriceUnitFromSizes()),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
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
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          setStateDialog(() {
                            _addSizePriceUnitField();
                          });
                        },
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'দাম'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'ইউনিট'),
                    ),
                    TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(labelText: 'সাইজ'),
                    ),
                  ],
                  // UPDATED: Dropdown for categories
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _supabase
                        .from('categories')
                        .select('id, categories_name'),
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
                        // UPDATED: initialValue is now the UUID
                        value: selectedAddCategory.isNotEmpty
                            ? selectedAddCategory
                            : null,
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            // UPDATED: value is the ID
                            value: category['id']
                                .toString(), // Convert int to String
                            // UPDATED: display text is the name
                            child: Text(category['categories_name']),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            // UPDATED: newValue is now the UUID
                            selectedAddCategory = newValue!;
                          });
                        },
                        decoration:
                            const InputDecoration(labelText: 'ক্যাটাগরি'),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: pickImage,
                        child: const Text('ছবি সিলেক্ট করুন'),
                      ),
                      const SizedBox(width: 8),
                      if (imageUrl.isNotEmpty)
                        Image.network(imageUrl, width: 50, height: 50),
                    ],
                  ),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(labelText: 'ছবি URL'),
                    onChanged: (value) =>
                        setStateDialog(() => imageUrl = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: pickVideo,
                        child: const Text('ভিডিও সিলেক্ট করুন'),
                      ),
                      const SizedBox(width: 8),
                      if (videoUrl.isNotEmpty)
                        Expanded(
                          child: SelectableText(
                            videoUrl,
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                  TextField(
                    controller: videoUrlController,
                    decoration: const InputDecoration(labelText: 'ভিডিও URL'),
                    onChanged: (value) =>
                        setStateDialog(() => videoUrl = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('বাতিল করুন'),
              ),
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
                      'userstocks': int.tryParse(stockController.text) ?? 0,
                      'userscompanys': companyController.text,
                      'usercolors': colorController.text,
                      // UPDATED: Now saves the UUID
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('✅ প্রোডাক্ট আপডেট করা হয়েছে')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ আপডেট করতে সমস্যা: $e')),
                    );
                  } finally {
                    setState(() => _isUploading = false);
                  }
                },
                child: const Text('আপডেট করুন'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('🛒 অ্যাডমিন সাব-আইটেম প্যানেল'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpansionTile(
                title: const Text('➕ নতুন সাব-আইটেম যুক্ত করুন'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // UPDATED: Dropdown for categories in "Add Product" section
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
                                  value: category['id']
                                      .toString(), // Convert int to String
                                  child: Text(category['categories_name']),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedAddCategory = newValue!;
                                });
                              },
                              decoration:
                                  const InputDecoration(labelText: 'ক্যাটাগরি'),
                            );
                          },
                        ),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'নাম'),
                        ),
                        TextField(
                          controller: subItemController,
                          decoration:
                              const InputDecoration(labelText: 'সাব-আইটেম'),
                        ),
                        TextField(
                          controller: detailsController,
                          decoration:
                              const InputDecoration(labelText: 'বিস্তারিত'),
                        ),
                        TextField(
                          controller: discountController,
                          decoration:
                              const InputDecoration(labelText: 'ডিসকাউন্ট'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: stockController,
                          decoration: const InputDecoration(labelText: 'স্টক'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: companyController,
                          decoration:
                              const InputDecoration(labelText: 'কোম্পানি'),
                        ),
                        TextField(
                          controller: colorController,
                          decoration: const InputDecoration(labelText: 'রং'),
                        ),
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
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: entry['size'],
                                        decoration: InputDecoration(
                                          labelText: 'সাইজ ${index + 1}',
                                        ),
                                        onChanged: (_) => setState(() =>
                                            _updateMainPriceUnitFromSizes()),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: entry['price'],
                                        decoration: InputDecoration(
                                          labelText: 'দাম ${index + 1}',
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() =>
                                            _updateMainPriceUnitFromSizes()),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: entry['unit'],
                                        decoration: InputDecoration(
                                          labelText: 'ইউনিট ${index + 1}',
                                        ),
                                        onChanged: (_) => setState(() =>
                                            _updateMainPriceUnitFromSizes()),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle),
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
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  _addSizePriceUnitField();
                                });
                              },
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: priceController,
                            decoration: const InputDecoration(labelText: 'দাম'),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: unitController,
                            decoration:
                                const InputDecoration(labelText: 'ইউনিট'),
                          ),
                          TextField(
                            controller: sizeController,
                            decoration:
                                const InputDecoration(labelText: 'সাইজ'),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isUploading ? null : pickImage,
                              child: const Text('ছবি সিলেক্ট করুন'),
                            ),
                            const SizedBox(width: 10),
                            if (imageUrl.isNotEmpty)
                              Image.network(imageUrl, width: 50, height: 50),
                          ],
                        ),
                        TextField(
                          controller: imageUrlController,
                          decoration:
                              const InputDecoration(labelText: 'ছবি URL'),
                          onChanged: (value) =>
                              setState(() => imageUrl = value),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _isUploading ? null : pickVideo,
                              child: const Text('ভিডিও সিলেক্ট করুন'),
                            ),
                            const SizedBox(width: 10),
                            if (videoUrl.isNotEmpty)
                              Expanded(
                                child: SelectableText(
                                  videoUrl,
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                          ],
                        ),
                        TextField(
                          controller: videoUrlController,
                          decoration: const InputDecoration(
                            labelText: 'ভিডিও URL',
                          ),
                          onChanged: (value) =>
                              setState(() => videoUrl = value),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('⚠️ সব ফিল্ড পূরণ করুন'),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    setState(() => _isUploading = true);

                                    final Map<String, dynamic> addData = {
                                      'usernames': nameController.text.trim(),
                                      'userItem': subItemController.text.trim(),
                                      'userdetailss':
                                          detailsController.text.trim(),
                                      'userdiscounts': int.tryParse(
                                            discountController.text.trim(),
                                          ) ??
                                          0,
                                      'userstocks': int.tryParse(
                                            stockController.text.trim(),
                                          ) ??
                                          0,
                                      'userscompanys':
                                          companyController.text.trim(),
                                      'usercolors': colorController.text.trim(),
                                      // UPDATED: Now saves the UUID
                                      'UCategorys': selectedAddCategory,
                                      'userimageUrls': imageUrlController.text,
                                      'uservideoUrls': videoUrlController.text,
                                      'createdAt':
                                          DateTime.now().toIso8601String(),
                                    };

                                    if (_hasSizes) {
                                      addData['sizes'] = _sizePriceUnitList
                                          .map((entry) => {
                                                'size': entry['size']?.text,
                                                'price': double.tryParse(
                                                        entry['price']?.text ??
                                                            '') ??
                                                    0,
                                                'unit': entry['unit']?.text,
                                              })
                                          .toList();
                                    } else {
                                      addData['price'] = double.tryParse(
                                              priceController.text.trim()) ??
                                          0;
                                      addData['unit'] =
                                          unitController.text.trim();
                                      addData['size'] =
                                          sizeController.text.trim();
                                    }

                                    await _supabase
                                        .from('ponno')
                                        .insert(addData);

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

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✅ প্রোডাক্ট সফলভাবে যোগ করা হয়েছে',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('❌ ত্রুটি: $e')),
                                    );
                                  } finally {
                                    setState(() => _isUploading = false);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'নাম দিয়ে খুঁজুন',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {
                  _futureProducts = _fetchProducts();
                }),
              ),
              const SizedBox(height: 12),
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
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorWidget(String error) {
    return Center(child: Text('ত্রুটি: $error'));
  }

  Widget _buildEmptyWidget() {
    return const Center(child: Text('কোনো প্রোডাক্ট পাওয়া যায়নি'));
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    final groupedProducts = _groupProductsBySubItem(products);

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        subItemName,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        childAspectRatio: 0.6,
        crossAxisSpacing: 3,
        mainAxisSpacing: 5,
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
    // UPDATED: Access category name from nested object
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAdminProductImage(
            imageUrl,
            discount,
            stock,
          ),
          _buildProductInfo(
              name, displayPrice, discountedPrice, discount, displayUnit),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('এডিট'),
                    onPressed: () => showEditDialog(docId, product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('ডিলিট'),
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
                                await deleteProduct(docId, imageUrl, videoUrl);
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProductImage(
    String imageUrl,
    int discount,
    int stock,
  ) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-$discount%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
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
    );
  }

  Widget _buildProductInfo(
    String name,
    double price,
    String discountedPrice,
    int discount,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 1,
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
              const SizedBox(width: 8),
              if (discount > 0)
                Text(
                  '৳${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
