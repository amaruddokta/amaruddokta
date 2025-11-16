import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:amar_uddokta/uddoktaa/screens/zoomable_image_screen.dart';

class CommentSection extends StatefulWidget {
  final String productId;

  const CommentSection({super.key, required this.productId});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<File> _imageFiles = [];
  bool _isUploading = false;
  final int maxImages = 3;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      List<File> newImages = [];
      for (var pickedFile in pickedFiles) {
        final imageFile = File(pickedFile.path);
        final size = await imageFile.length();

        if (size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${pickedFile.name} ছবির সাইজ 5MB এর কম হতে হবে')),
          );
          continue;
        }
        newImages.add(imageFile);
      }

      setState(() {
        _imageFiles.addAll(newImages.take(maxImages - _imageFiles.length));
        if (_imageFiles.length > maxImages) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('সর্বোচ্চ $maxImagesটি ছবি নির্বাচন করা যাবে')),
          );
        }
      });
    } else {
      print('কোন ছবি নির্বাচন করা হয়নি।');
    }
  }

  Future<String?> _uploadImageToSupabaseStorage(File image) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1000,
        minHeight: 1000,
      );

      if (compressedXFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ছবি কম্প্রেস করতে ব্যর্থ হয়েছে')),
        );
        return null;
      }
      File compressedImage = File(compressedXFile.path);

      final String fileName =
          'comment_images/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final String fileExtension = image.path.split('.').last;
      final String path = '$fileName.$fileExtension';

      await _supabase.storage.from('comment_images').upload(
            path,
            compressedImage,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final String downloadUrl =
          _supabase.storage.from('comment_images').getPublicUrl(path);
      print('Supabase Storage আপলোড সফল: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Supabase Storage আপলোড এরর: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('আপলোড ব্যর্থ: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমেন্ট করতে লগইন করুন।')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty && _imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমেন্ট অথবা ছবি দিন।')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    List<String> imageUrls = [];
    if (_imageFiles.isNotEmpty) {
      for (var imageFile in _imageFiles) {
        String? uploadedUrl = await _uploadImageToSupabaseStorage(imageFile);
        if (uploadedUrl != null) {
          imageUrls.add(uploadedUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'একটি ছবি আপলোড ব্যর্থ হয়েছে: ${imageFile.path.split('/').last}')),
          );
          setState(() {
            _isUploading = false;
          });
          return;
        }
      }
    }

    String fetchedUserName = 'Anonymous';
    String fetchedUserEmail = user.email ?? 'N/A';

    try {
      final response = await _supabase
          .from('users')
          .select('name, email')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        fetchedUserName =
            response['name'] ?? user.userMetadata?['name'] ?? 'Anonymous';
        fetchedUserEmail = response['email'] ?? user.email ?? 'N/A';
      } else {
        fetchedUserName = user.userMetadata?['name'] ?? 'Anonymous';
      }
    } catch (e) {
      print('ইউজার ডেটা লোড করতে সমস্যা: $e');
      fetchedUserName = user.userMetadata?['name'] ?? 'Anonymous';
    }

    try {
      await _supabase.from('product_comments').insert({
        // ডাটাবেস কলামের নাম snake_case এ হবে
        'product_id': widget.productId,
        'user_id': user.id,
        'user_name': fetchedUserName,
        'user_email': fetchedUserEmail,
        'comment': _commentController.text.trim(),
        'image_urls': imageUrls,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      _commentController.clear();
      setState(() {
        _imageFiles.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমেন্ট সফলভাবে যুক্ত হয়েছে')),
      );
    } catch (e) {
      print('কমেন্ট সাবমিট করতে সমস্যা: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমেন্ট যুক্ত করতে ব্যর্থ হয়েছে')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'মতামত',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCommentInput(),
          const SizedBox(height: 16),
          _buildCommentList(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Column(
      children: [
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'আপনার মতামত লিখুন...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.image),
              onPressed: _pickImage,
            ),
          ),
          maxLines: 3,
        ),
        if (_imageFiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _imageFiles.asMap().entries.map((entry) {
                int index = entry.key;
                File imageFile = entry.value;
                return Stack(
                  children: [
                    Image.file(
                      imageFile,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _imageFiles.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        _isUploading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _submitComment,
                child: const Text('কমেন্ট করুন'),
              ),
      ],
    );
  }

  Widget _buildCommentList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('product_comments')
          .select()
          // ডাটাবেস কলামের নাম snake_case এ হবে
          .eq('product_id', widget.productId)
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .asStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('কমেন্ট লোড করতে সমস্যা: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('কোন মতামত নেই।');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final commentData = snapshot.data![index];
            // ডাটাবেস থেকে আসা ডেটার কী snake_case এ
            final userName = commentData['user_name'] ?? 'Anonymous';
            final commentText = commentData['comment'] ?? '';
            final commentImageUrls =
                commentData['image_urls'] as List<dynamic>?;
            final timestamp = commentData['created_at'] as String?;

            return CommentItemWidget(
              commentData: commentData,
              userName: userName,
              commentText: commentText,
              commentImageUrls: commentImageUrls,
              timestamp: timestamp,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class CommentItemWidget extends StatefulWidget {
  final Map<String, dynamic> commentData;
  final String userName;
  final String commentText;
  final List<dynamic>? commentImageUrls;
  final String? timestamp;

  const CommentItemWidget({
    super.key,
    required this.commentData,
    required this.userName,
    required this.commentText,
    this.commentImageUrls,
    this.timestamp,
  });

  @override
  State<CommentItemWidget> createState() => _CommentItemWidgetState();
}

class _CommentItemWidgetState extends State<CommentItemWidget> {
  bool _isExpanded = false;

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} সেকেন্ড আগে';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} মিনিট আগে';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ঘন্টা আগে';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} দিন আগে';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (widget.timestamp != null)
                        Text(
                          _formatTimestamp(widget.timestamp!),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.commentText.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    widget.commentText,
                    maxLines: _isExpanded ? null : 3,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            if (widget.commentImageUrls != null &&
                widget.commentImageUrls!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: widget.commentImageUrls!.map((url) {
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => ZoomableImageScreen(imageUrl: url));
                    },
                    child: Image.network(
                      url,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
