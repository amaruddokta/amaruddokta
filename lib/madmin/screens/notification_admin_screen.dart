import 'dart:io'; // For File
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For ImagePicker
import 'package:path/path.dart' as path; // For path operations

class NotificationAdminScreen extends StatefulWidget {
  const NotificationAdminScreen({super.key});

  @override
  State<NotificationAdminScreen> createState() =>
      _NotificationAdminScreenState();
}

class _NotificationAdminScreenState extends State<NotificationAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _imageUrlController = TextEditingController();
  File? _selectedImage; // State variable for selected image

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      return null;
    }

    try {
      final fileName = path.basename(_selectedImage!.path);
      final destination = 'notifications/$fileName';
      await Supabase.instance.client.storage
          .from('notifications')
          .upload(destination, _selectedImage!);
      return Supabase.instance.client.storage
          .from('notifications')
          .getPublicUrl(destination);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _addOrUpdateNotification({String? docId}) async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      } else if (_imageUrlController.text.isNotEmpty) {
        imageUrl = _imageUrlController.text;
      }

      final data = {
        'message': _messageController.text,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
      };
      if (docId == null) {
        await Supabase.instance.client.from('notifications').insert(data);
      } else {
        await Supabase.instance.client
            .from('notifications')
            .update(data)
            .eq('id', docId);
      }
      _messageController.clear();
      _imageUrlController.clear();
      setState(() {
        _selectedImage = null; // Clear selected image after upload
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showNotificationDialog({Map<String, dynamic>? notification}) {
    if (notification != null) {
      final data = notification;
      _messageController.text = data['message'] ?? '';
      _imageUrlController.text = data['imageUrl'] ?? '';
    } else {
      _messageController.clear();
      _imageUrlController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            notification == null ? 'Add Notification' : 'Edit Notification'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a message' : null,
                maxLines: 3,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration:
                    const InputDecoration(labelText: 'Image URL (optional)'),
              ),
              const SizedBox(height: 10),
              _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    )
                  : (notification != null && notification['imageUrl'] != null)
                      ? Image.network(
                          notification['imageUrl'] as String,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                      : Container(), // Added semicolon here
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _selectedImage = null; // Clear selected image on cancel
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                _addOrUpdateNotification(docId: notification?['id']),
            child: Text(notification == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showNotificationDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('notifications')
            .stream(primaryKey: ['id']).order('createdAt', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications found.'));
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification;
              final message = data['message'] as String;
              final imageUrl = data['imageUrl'] as String?;

              return ListTile(
                title: Text(message),
                subtitle: imageUrl != null ? Text(imageUrl) : null,
                leading: imageUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(imageUrl),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showNotificationDialog(notification: notification),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        if (imageUrl != null) {
                          try {
                            final path =
                                imageUrl.substring(imageUrl.indexOf('/o/') + 3);
                            await Supabase.instance.client.storage
                                .from('notifications')
                                .remove([path]);
                          } catch (e) {
                            print('Error deleting image from storage: $e');
                          }
                        }
                        await Supabase.instance.client
                            .from('notifications')
                            .delete()
                            .eq('id', notification['id']);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
