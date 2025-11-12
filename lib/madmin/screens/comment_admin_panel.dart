// lib/dokane/screens/comment_admin_panel.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart'; // For Get.to navigation
import 'package:amar_uddokta/uddoktaa/screens/zoomable_image_screen.dart'; // For zoomable images

class CommentAdminPanel extends StatefulWidget {
  final String? productId;

  const CommentAdminPanel({
    super.key,
    this.productId,
  });

  @override
  _CommentAdminPanelState createState() => _CommentAdminPanelState();
}

class _CommentAdminPanelState extends State<CommentAdminPanel> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _commentsStream;
  String _filterStatus = 'all';
  final List<String> _filterOptions = ['all', 'approved', 'pending', 'blocked'];

  @override
  void initState() {
    super.initState();
    _initializeCommentsStream();
  }

  void _initializeCommentsStream() {
    var query = _supabase.from("product_comments").select();

    if (widget.productId != null && widget.productId!.isNotEmpty) {
      query = query.eq('productId', widget.productId!);
    }

    final orderedQuery = query.order("timestamp", ascending: false);

    _commentsStream = orderedQuery.asStream().map(
          (event) => event.map((e) => e).toList(),
        );
  }

  void _updateFilter(String status) {
    setState(() {
      _filterStatus = status;

      var query = _supabase.from("product_comments").select();

      if (widget.productId != null && widget.productId!.isNotEmpty) {
        query = query.eq('productId', widget.productId!);
      }

      if (status != 'all') {
        query = query.eq('status', status);
      }

      final orderedQuery = query.order("timestamp", ascending: false);

      _commentsStream = orderedQuery.asStream().map(
            (event) => event.map((e) => e).toList(),
          );
    });
  }

  Future<void> _updateCommentStatus(String commentId, String status) async {
    try {
      await _supabase.from('product_comments').update({
        'status': status,
        'moderatedAt': DateTime.now().toIso8601String(),
        'moderatedBy': _supabase.auth.currentUser?.id,
      }).eq('id', commentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment ${status.toUpperCase()}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      // কমেন্টটি খুঁজে বের করুন
      final commentData = await _supabase
          .from('product_comments')
          .select('imageUrls')
          .eq('id', commentId)
          .maybeSingle();

      if (commentData != null) {
        final commentImageUrls = commentData['imageUrls'] as List<dynamic>?;
        if (commentImageUrls != null && commentImageUrls.isNotEmpty) {
          // স্টোরেজ থেকে ইমেজগুলো ডিলিট করুন
          for (var url in commentImageUrls) {
            try {
              final uri = Uri.parse(url);
              final pathSegments = uri.pathSegments;
              // বাকেটের নামের পর থেকে পাথ খুঁজে বের করা
              final bucketIndex = pathSegments.indexOf('comment_images');
              if (bucketIndex != -1) {
                final path = pathSegments.sublist(bucketIndex).join('/');
                await _supabase.storage.from('comment_images').remove([path]);
                print('Deleted image from storage: $path');
              }
            } catch (e) {
              print('Error deleting image $url from storage: $e');
            }
          }
        }
      }

      // কমেন্ট ডকুমেন্টটি ডিলিট করুন
      await _supabase.from('product_comments').delete().eq('id', commentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Comment and associated images deleted permanently')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment or images: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment Admin Panel'),
        backgroundColor: Colors.red,
        actions: [
          PopupMenuButton<String>(
            onSelected: _updateFilter,
            itemBuilder: (context) => _filterOptions.map((option) {
              return PopupMenuItem(
                value: option,
                child: Text('Filter: ${option.toUpperCase()}'),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _commentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.data!.isEmpty) {
                  return const Center(child: Text('No comments found'));
                }

                final comments = snapshot.data!;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final data = comment;
                    final status = data['status'] ?? 'pending';
                    final userName = data['userName'] ?? 'Anonymous';
                    final commentText = data['comment'] ?? '';
                    final commentImageUrls =
                        data['imageUrls'] as List<dynamic>?;
                    final commentId = data['id']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _getStatusColor(status),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : '?'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        data['timestamp'] != null
                                            ? DateTime.parse(data['timestamp'])
                                                .toLocal()
                                                .toString()
                                            : 'Unknown time',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              commentText,
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (commentImageUrls != null &&
                                commentImageUrls.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: commentImageUrls.map<Widget>((url) {
                                  return GestureDetector(
                                    onTap: () {
                                      Get.to(() =>
                                          ZoomableImageScreen(imageUrl: url));
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 100,
                                          width: 100,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.thumb_up,
                                    size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 4),
                                Text('${data['likes'] ?? 0}'),
                                const SizedBox(width: 16),
                                Icon(Icons.thumb_down,
                                    size: 16, color: Colors.red[700]),
                                const SizedBox(width: 4),
                                Text('${data['dislikes'] ?? 0}'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status != 'approved')
                                  TextButton.icon(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    label: const Text('Approve'),
                                    onPressed: () => _updateCommentStatus(
                                        commentId, 'approved'),
                                  ),
                                if (status != 'blocked')
                                  TextButton.icon(
                                    icon: const Icon(Icons.block,
                                        color: Colors.red),
                                    label: const Text('Block'),
                                    onPressed: () => _updateCommentStatus(
                                        commentId, 'blocked'),
                                  ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  label: const Text('Delete'),
                                  onPressed: () => _deleteComment(commentId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        children: _filterOptions.map((option) {
          return ChoiceChip(
            label: Text(option.toUpperCase()),
            selected: _filterStatus == option,
            onSelected: (selected) {
              if (selected) _updateFilter(option);
            },
            selectedColor: Colors.red[100],
            backgroundColor: Colors.grey[200],
          );
        }).toList(),
      ),
    );
  }
}
