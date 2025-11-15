import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amar_uddokta/uddoktaa/models/user.dart' as AppUser;
import 'package:amar_uddokta/uddoktaa/services/user_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _searchQuery = '';
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ইউজার তালিকা'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'ইউজার খুঁজুন নাম/ফোন/ইমেইল দিয়ে',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<AppUser.User>>(
        stream: _userService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('কোনো ইউজার পাওয়া যায়নি।'));
          }

          final allUsers = snapshot.data!;
          final filteredUsers = allUsers.where((user) {
            final name = user.name.toLowerCase();
            final phone = user.phone.toLowerCase();
            final email = user.email.toLowerCase();
            final village = user.village.toLowerCase();
            final ward = user.ward?.toLowerCase() ?? '';
            final house = user.house?.toLowerCase() ?? '';
            final road = user.road?.toLowerCase() ?? '';
            final upazila = user.upazila.toLowerCase();
            final district = user.district.toLowerCase();

            return name.contains(_searchQuery) ||
                phone.contains(_searchQuery) ||
                email.contains(_searchQuery) ||
                village.contains(_searchQuery) ||
                ward.contains(_searchQuery) ||
                house.contains(_searchQuery) ||
                road.contains(_searchQuery) ||
                upazila.contains(_searchQuery) ||
                district.contains(_searchQuery);
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(
                child: Text(
                    'আপনার অনুসন্ধানের সাথে মেলে এমন কোনো ইউজার পাওয়া যায়নি।'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // StreamBuilder automatically refreshes, but we can trigger a re-fetch if needed
              // For now, just return a completed future
              await Future.value();
            },
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.teal.shade100,
                      backgroundImage:
                          user.imageUrl != null && user.imageUrl!.isNotEmpty
                              ? NetworkImage(user.imageUrl!)
                              : null,
                      child: user.imageUrl == null || user.imageUrl!.isEmpty
                          ? Icon(Icons.person, color: Colors.teal.shade700)
                          : null,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(user.phone),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.email,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(user.email,
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${user.village}, ${user.upazila}, ${user.district}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(user.status ?? 'pending'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'স্ট্যাটাস: ${user.status?.toUpperCase() ?? 'PENDING'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.teal.shade700),
                      onSelected: (value) async {
                        if (value == 'approve') {
                          await _updateUserStatus(user.id, 'approved');
                        } else if (value == 'reject') {
                          await _updateUserStatus(user.id, 'rejected');
                        } else if (value == 'delete') {
                          await _deleteUser(user.id, user.imageUrl);
                        } else if (value == 'details') {
                          _showUserDetails(user);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Approve'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Reject'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
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
        },
      ),
    );
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      final user = await _userService.getUserById(userId);
      if (user != null) {
        await _userService.updateUser(user.copyWith(status: status));
        Get.snackbar(
          'সফল',
          'ইউজার স্ট্যাটাস $status করা হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      }
    } catch (e) {
      debugPrint('Error updating user status: $e');
      Get.snackbar(
        'ত্রুটি',
        'স্ট্যাটাস আপডেট করতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> _deleteUser(String userId, String? imageUrl) async {
    final confirmDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('ইউজার ডিলিট করুন'),
        content:
            const Text('আপনি কি নিশ্চিত যে আপনি এই ইউজারকে ডিলিট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('হ্যাঁ, ডিলিট করুন'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        // Delete profile image from Supabase Storage if exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            // Assuming 'profile_images' is the bucket name
            final String path = imageUrl.split('/').last;
            await _userService.deleteProfileImage(
                path); // Need to add this method to UserService
          } catch (e) {
            debugPrint('Error deleting profile image: $e');
          }
        }

        // Delete user from Supabase Database
        await _userService.deleteUser(userId);

        Get.snackbar(
          'সফল',
          'ইউজার সফলভাবে ডিলিট হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } catch (e) {
        debugPrint('Error deleting user: $e');
        Get.snackbar(
          'ত্রুটি',
          'ইউজার ডিলিট করতে সমস্যা হয়েছে: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    }
  }

  void _showUserDetails(AppUser.User user) {
    final name = user.name;
    final email = user.email;
    final phone = user.phone;
    final division = user.division;
    final district = user.district;
    final upazila = user.upazila;
    final union = user.union ?? '';
    final village = user.village;
    final ward = user.ward ?? '';
    final house = user.house ?? '';
    final road = user.road ?? '';
    final referCode = user.referCode ?? '';
    final referBalance = user.referBalance?.toString() ?? '0';
    final status = user.status ?? 'pending';
    final createdAt = user.createdAt?.toIso8601String().split('T')[0] ?? '';
    final imageUrl = user.imageUrl;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ইউজার বিস্তারিত',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade100,
                  backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Icon(Icons.person,
                          size: 50, color: Colors.teal.shade700)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('নাম', name),
              _buildDetailRow('ইমেইল', email),
              _buildDetailRow('ফোন', phone),
              _buildDetailRow('রেফারেল কোড', referCode),
              _buildDetailRow('রেফারেল ব্যালেন্স', '৳$referBalance'),
              const Divider(),
              const Text(
                'ঠিকানা',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('বিভাগ', division),
              _buildDetailRow('জেলা', district),
              _buildDetailRow('উপজেলা', upazila),
              _buildDetailRow('ইউনিয়ন', union),
              _buildDetailRow('গ্রাম', village),
              _buildDetailRow('ওয়ার্ড', ward),
              _buildDetailRow('বাড়ি', house),
              _buildDetailRow('রোড', road),
              const Divider(),
              _buildDetailRow('স্ট্যাটাস', status.toUpperCase()),
              if (createdAt.isNotEmpty)
                _buildDetailRow('তৈরির তারিখ', createdAt),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
