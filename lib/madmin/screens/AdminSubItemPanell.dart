import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

class AdminSubItemPanel extends StatefulWidget {
  const AdminSubItemPanel({Key? key}) : super(key: key);

  @override
  State<AdminSubItemPanel> createState() => _AdminSubItemPanelState();
}

class _AdminSubItemPanelState extends State<AdminSubItemPanel> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _storagePath =
      'subitem'; // The specified path in Supabase Storage

  // কন্ট্রোলার্স
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

  String selectedCategory = "সব ক্যাটাগরি";
  String selectedAddCategory = "";
  String imageUrl = '';
  String videoUrl = '';
  bool _isUploading = false;

  // Size-related variables
  final List<Map<String, TextEditingController>> _sizePriceUnitList = [];
  bool _hasSizes = false;

  // Supabase Storage-এ ফাইল আপলোড
  Future<String?> uploadFileToSupabase(
    Uint8List fileBytes,
    String fileName,
    String contentType,
  ) async {
    try {
      await _supabase.storage.from(_storagePath).uploadBinary(
          fileName, fileBytes,
          fileOptions: FileOptions(contentType: contentType));

      final publicUrl =
          _supabase.storage.from(_storagePath).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Supabase Storage Upload error: $e');
      return null;
    }
  }

  // Size-related methods
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

  // ইমেজ পিক ও আপলোড
  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isUploading = true);

        // Compress image
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

        String fileExtension = path.extension(pickedFile.path);
        if (fileExtension.isEmpty || fileExtension == '.') {
          fileExtension = '.jpg';
        }
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
        final uploadedUrl = await uploadFileToSupabase(
          Uint8List.fromList(compressedBytes),
          fileName,
          'image/jpeg',
        );

        if (uploadedUrl != null) {
          setState(() {
            imageUrl = uploadedUrl;
            imageUrlController.text = uploadedUrl; // Update controller
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ ত্রুটি: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ভিডিও পিক ও আপলোড
  Future<void> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);

        final file = result.files.single;
        final String? filePath = file.path;

        if (filePath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ভিডিও ফাইল পাথ পাওয়া যায়নি')),
          );
          return;
        }

        // Compress video
        final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
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

        String fileExtension = path.extension(file.name);
        if (fileExtension.isEmpty || fileExtension == '.') {
          fileExtension = '.mp4';
        }
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
        final uploadedUrl = await uploadFileToSupabase(
          compressedVideoBytes,
          fileName,
          'video/mp4',
        );

        if (uploadedUrl != null) {
          setState(() {
            videoUrl = uploadedUrl;
            videoUrlController.text = uploadedUrl; // Update controller
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ ত্রুটি: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // প্রোডাক্ট ডিলিট
  Future<void> deleteProduct(
    String docId,
    String? imageUrl,
    String? videoUrl,
  ) async {
    try {
      setState(() => _isUploading = true);

      // Supabase Storage থেকে ফাইল ডিলিট
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final fileName = imageUrl.split('/').last;
        await _supabase.storage.from(_storagePath).remove([fileName]);
      }
      if (videoUrl != null && videoUrl.isNotEmpty) {
        final fileName = videoUrl.split('/').last;
        await _supabase.storage.from(_storagePath).remove([fileName]);
      }

      // Supabase থেকে ডকুমেন্ট ডিলিট
      await _supabase.from('products').delete().eq('id', docId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ প্রোডাক্ট ডিলিট করা হয়েছে')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ ডিলিট করতে সমস্যা: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // এডিট ডায়ালগ
  void showEditDialog(String docId, Map<String, dynamic> data) {
    nameController.text = data['name'] ?? '';
    subItemController.text = data['subItemName'] ?? '';
    unitController.text = data['unit'] ?? '';
    detailsController.text = data['details'] ?? '';
    priceController.text = (data['price'] ?? '').toString();
    discountController.text = (data['discount'] ?? '').toString();
    stockController.text = (data['stock'] ?? '').toString();
    companyController.text = data['company'] ?? '';
    colorController.text = data['color'] ?? '';
    sizeController.text = data['size'] ?? '';
    selectedAddCategory = data['category'] ?? '';
    imageUrl = data['imageUrl'] ?? '';
    videoUrl = data['videoUrl'] ?? '';
    imageUrlController.text = imageUrl; // Initialize controller
    videoUrlController.text = videoUrl; // Initialize controller

    // Clear existing size fields
    for (var entry in _sizePriceUnitList) {
      entry['size']?.dispose();
      entry['price']?.dispose();
      entry['unit']?.dispose();
    }
    _sizePriceUnitList.clear();

    // Load sizes data if exists
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
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _supabase
                                .from('categories')
                                .stream(primaryKey: ['id']),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }
                              if (snapshot.hasError) {
                                return const Text('Something went wrong');
                              }
                              return DropdownButtonFormField<String>(
                                value: selectedAddCategory.isNotEmpty
                                    ? selectedAddCategory
                                    : null,
                                items: snapshot.data!.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category['name'],
                                    child: Text(category['name']),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setStateDialog(() {
                                    selectedAddCategory = newValue!;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'ক্যাটাগরি',
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
                                'name': nameController.text,
                                'subItemName': subItemController.text,
                                'details': detailsController.text,
                                'discount':
                                    int.tryParse(discountController.text) ?? 0,
                                'stock':
                                    int.tryParse(stockController.text) ?? 0,
                                'company': companyController.text,
                                'color': colorController.text,
                                'category': selectedAddCategory,
                                'imageUrl': imageUrlController.text,
                                'videoUrl': videoUrlController.text,
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
                                  .from('products')
                                  .update(updateData)
                                  .eq('id', docId);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('✅ প্রোডাক্ট আপডেট করা হয়েছে')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('❌ আপডেট করতে সমস্যা: $e')),
                              );
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
    imageUrlController.dispose(); // Dispose new controller
    videoUrlController.dispose(); // Dispose new controller

    // Dispose size controllers
    for (var entry in _sizePriceUnitList) {
      entry['size']?.dispose();
      entry['price']?.dispose();
      entry['unit']?.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🛒 অ্যাডমিন সাব-আইটেম প্যানেল')),
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
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _supabase
                            .from('categories')
                            .stream(primaryKey: ['id']),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return const Text('Something went wrong');
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedAddCategory.isNotEmpty
                                ? selectedAddCategory
                                : null,
                            items: snapshot.data!.map((category) {
                              return DropdownMenuItem<String>(
                                value: category['name'],
                                child: Text(category['name']),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedAddCategory = newValue!;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'ক্যাটাগরি',
                            ),
                          );
                        },
                      ),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'নাম'),
                      ),
                      TextField(
                        controller: subItemController,
                        decoration: const InputDecoration(
                          labelText: 'সাব-আইটেম',
                        ),
                      ),
                      TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'ইউনিট'),
                      ),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'দাম'),
                      ),
                      TextField(
                        controller: discountController,
                        decoration: const InputDecoration(
                          labelText: 'ডিসকাউন্ট',
                        ),
                      ),
                      TextField(
                        controller: stockController,
                        decoration: const InputDecoration(labelText: 'স্টক'),
                      ),
                      TextField(
                        controller: companyController,
                        decoration: const InputDecoration(
                          labelText: 'কোম্পানি',
                        ),
                      ),
                      TextField(
                        controller: colorController,
                        decoration: const InputDecoration(labelText: 'রং'),
                      ),
                      TextField(
                        controller: sizeController,
                        decoration: const InputDecoration(labelText: 'সাইজ'),
                      ),
                      TextField(
                        controller: detailsController,
                        decoration: const InputDecoration(
                          labelText: 'বিস্তারিত',
                        ),
                      ),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: entry['size']!,
                                      decoration: InputDecoration(
                                        labelText: 'সাইজ ${index + 1}',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() =>
                                          _updateMainPriceUnitFromSizes()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: entry['price']!,
                                      decoration: InputDecoration(
                                        labelText: 'দাম ${index + 1}',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() =>
                                          _updateMainPriceUnitFromSizes()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: entry['unit']!,
                                      decoration: InputDecoration(
                                        labelText: 'ইউনিট ${index + 1}',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      onChanged: (_) => setState(() =>
                                          _updateMainPriceUnitFromSizes()),
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
                          controller: sizeController,
                          decoration: const InputDecoration(labelText: 'সাইজ'),
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
                        decoration: const InputDecoration(labelText: 'ছবি URL'),
                        onChanged: (value) => setState(() => imageUrl = value),
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
                        onChanged: (value) => setState(() => videoUrl = value),
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
                                    'name': nameController.text.trim(),
                                    'subItemName':
                                        subItemController.text.trim(),
                                    'unit': unitController.text.trim(),
                                    'details': detailsController.text.trim(),
                                    'discount': int.tryParse(
                                          discountController.text.trim(),
                                        ) ??
                                        0,
                                    'stock': int.tryParse(
                                          stockController.text.trim(),
                                        ) ??
                                        0,
                                    'company': companyController.text.trim(),
                                    'color': colorController.text.trim(),
                                    'category': selectedAddCategory,
                                    'imageUrl': imageUrlController
                                        .text, // Use controller value
                                    'videoUrl': videoUrlController
                                        .text, // Use controller value
                                    'createdAt':
                                        DateTime.now().toIso8601String(),
                                    'updatedAt':
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
                                      .from('products')
                                      .insert(addData);

                                  // ফিল্ড ক্লিয়ার
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
                                  imageUrlController
                                      .clear(); // Clear new controller
                                  videoUrlController
                                      .clear(); // Clear new controller

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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('products').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('ডেটা লোড করতে সমস্যা হয়েছে');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data?.where((product) {
                      if (selectedCategory != "সব ক্যাটাগরি" &&
                          product['category'] != selectedCategory) return false;
                      return product['name']?.toString().toLowerCase().contains(
                                searchController.text.toLowerCase(),
                              ) ??
                          false;
                    }).toList() ??
                    [];

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      child: ListTile(
                        leading: product['imageUrl'] != null &&
                                product['imageUrl'].toString().isNotEmpty
                            ? Image.network(
                                product['imageUrl'],
                                width: 50,
                                height: 50,
                              )
                            : const Icon(Icons.image),
                        title: Text(product['name'] ?? ''),
                        subtitle: Text(
                          '${product['category'] ?? ''} - ${product['company'] ?? ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showEditDialog(
                                product['id'],
                                product,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
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
                                          Navigator.pop(
                                              context); // Close the dialog
                                          await deleteProduct(
                                            product['id'],
                                            product['imageUrl'],
                                            product['videoUrl'],
                                          );
                                        },
                                        child: const Text('ডিলিট করুন'),
                                      ),
                                    ],
                                  ),
                                );
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
          ],
        ),
      ),
    );
  }
}
