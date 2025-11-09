import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ইউজার তালিকা'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
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
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('users')
            .stream(primaryKey: ['uid']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('কোনো ইউজার পাওয়া যায়নি।'));
          }

          final users = snapshot.data!.where((user) {
            final name = user['name']?.toLowerCase() ?? '';
            final phone = user['phone']?.toLowerCase() ?? '';
            final email = user['email']?.toLowerCase() ?? '';
            final village = user['village']?.toLowerCase() ?? '';
            final ward = user['ward']?.toLowerCase() ?? '';
            final house = user['house']?.toLowerCase() ?? '';
            final road = user['road']?.toLowerCase() ?? '';
            final upazila = user['upazila']?.toLowerCase() ?? '';
            final district = user['district']?.toLowerCase() ?? '';
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

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user['name'] ?? 'নাম নেই';
              final phone = user['phone'] ?? 'ফোন নেই';
              final email = user['email'] ?? 'ইমেইল নেই';
              final division = user['division'] ?? '';
              final district = user['district'] ?? '';
              final upazila = user['upazila'] ?? '';
              final village = user['village'] ?? '';
              final ward = user['ward'] ?? '';
              final house = user['house'] ?? '';
              final road = user['road'] ?? '';
              final imageUrl = user['imageUrl'];
              final status = user['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ফোন: $phone'),
                      Text('ইমেইল: $email'),
                      Text(
                          'ঠিকানা: $village, $ward, $house, $road, $upazila, $district, $division'),
                      Text('স্ট্যাটাস: ${status.toUpperCase()}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'approve') {
                        await Supabase.instance.client.from('users').update(
                            {'status': 'approved'}).eq('uid', user['uid']);
                      } else if (value == 'reject') {
                        await Supabase.instance.client.from('users').update(
                            {'status': 'rejected'}).eq('uid', user['uid']);
                      } else if (value == 'delete') {
                        await Supabase.instance.client
                            .from('users')
                            .delete()
                            .eq('uid', user['uid']);
                      } else if (value == 'details') {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('ইউজার বিস্তারিত'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('নাম: $name'),
                                Text('ইমেইল: $email'),
                                Text('ফোন: $phone'),
                                Text(
                                    'ঠিকানা: $village, $ward, $house, $road, $upazila, $district, $division'),
                                Text('স্ট্যাটাস: $status'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('বন্ধ করুন'),
                              )
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'approve', child: Text('Approve')),
                      PopupMenuItem(value: 'reject', child: Text('Reject')),
                      PopupMenuItem(value: 'details', child: Text('Details')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
