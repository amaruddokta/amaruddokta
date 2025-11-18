import 'package:amar_uddokta/myuddokta/widgets/background_container.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

class MyOrdersScreen extends StatelessWidget {
  // এই uid ভেরিয়েবলটি আসলে ভেতরের StreamBuilder থেকেই আসা উচিত, তবে সমস্যা নয়
  final uid = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;

  MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('আমার অর্ডারসমূহ'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: StreamBuilder<supabase_flutter.User?>(
            stream: supabase_flutter
                .Supabase.instance.client.auth.onAuthStateChange
                .map((data) => data.session?.user),
            builder: (context, authSnapshot) {
              if (!authSnapshot.hasData || authSnapshot.data == null) {
                return Center(child: Text('আপনি লগইন করেননি'));
              }
              // authSnapshot থেকেই uid নেওয়া হচ্ছে, যা সবচেয়ে নিরাপদ
              final uid = authSnapshot.data!.id;
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase_flutter.Supabase.instance.client
                    .from('orders')
                    // সমাধান: প্রাইমারি কি হলো 'order_id'
                    .stream(primaryKey: ['order_id'])
                    .eq('user_id', uid)
                    .order('placed_at', ascending: false),
                builder: (context, snapshot) {
                  debugPrint(
                      'MyOrdersScreen StreamBuilder - ConnectionState: ${snapshot.connectionState}');
                  if (snapshot.hasError) {
                    debugPrint(
                        'MyOrdersScreen StreamBuilder - Error: ${snapshot.error}');
                    return Center(
                        child: Text(
                            'ডেটা লোড করতে সমস্যা হয়েছে: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    debugPrint(
                        'MyOrdersScreen StreamBuilder - Waiting for data...');
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    debugPrint(
                        'MyOrdersScreen StreamBuilder - No orders found or data is null.');
                    return Center(child: Text('কোনো অর্ডার পাওয়া যায়নি'));
                  }
                  final orders = snapshot.data!;
                  debugPrint(
                      'MyOrdersScreen StreamBuilder - Orders found: ${orders.length}');
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      // সমস্ত camelCase কে snake_case এ পরিবর্তন করা হলো
                      final orderId = order['order_id'];
                      final grandTotal = order['grand_total'];
                      final paymentMethod = order['payment_method'];
                      // সমাধান: String থেকে DateTime এ কনভার্ট করা হচ্ছে
                      final placedAt = DateTime.parse(order['placed_at']);
                      final status = order['status'];
                      final items = List<Map>.from(order['items']);
                      final specialMessage = order['special_message'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ExpansionTile(
                          title: Text('অর্ডার: $orderId'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('মোট: ৳$grandTotal'),
                              Text('পেমেন্ট: $paymentMethod'),
                              Text('স্ট্যাটাস: ${_statusText(status)}',
                                  style:
                                      TextStyle(color: _statusColor(status))),
                              Text(
                                'সময়: ${placedAt.toLocal()}'.split('.')[0],
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          children: [
                            ListTile(
                              title: Text(
                                  'ক্রেতার নাম: ${order['user_name']}'), // সমাধান
                              subtitle:
                                  Text('ফোন: ${order['user_phone']}'), // সমাধান
                            ),
                            ListTile(
                              title: Text('ঠিকানা:'),
                              subtitle: Text(
                                  // ধরে নেওয়া হচ্ছে location JSON এর ভেতরের কীগুলো একই
                                  '${order['location']['house'] ?? ''}, ${order['location']['ward'] ?? ''}, ${order['location']['road'] ?? ''}, ${order['location']['village'] ?? ''}, ${order['location']['union'] ?? ''}, ${order['location']['upazila'] ?? ''}, ${order['location']['district'] ?? ''}, ${order['location']['division'] ?? ''}'),
                            ),
                            if (specialMessage.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.yellow[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.message,
                                            color: Colors.yellow[800],
                                            size: 16),
                                        SizedBox(width: 5),
                                        Text(
                                          'বিশেষ বার্তা:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.yellow[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      specialMessage,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ListTile(
                              title: Text(
                                  'ডেলিভারি চার্জ: ৳${order['delivery_charge']}'), // সমাধান
                            ),
                            _buildTransactionDetails(order),
                            const Divider(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text('অর্ডারের পণ্যসমূহ:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ...items.map((item) => ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['imageUrl'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                              Icons.image_not_supported,
                                              size: 60),
                                    ),
                                  ),
                                  title: Text(item['name']),
                                  trailing: Text(
                                      '${item['quantity']} × ৳${item['price']}'),
                                )),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  /*
                                  if (status == 'pending')
                                    TextButton(
                                      onPressed: () =>
                                          _showCancelDialog(context, order),
                                      child: Text('অর্ডার ক্যানসেল করুন',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  if (status == 'delivered')
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('রিভিউ সিস্টেম আসছে...'),
                                          ),
                                        );
                                      },
                                      child: Text('রিভিউ দিন'),
                                    ),
                                  TextButton.icon(
                                    icon: Icon(Icons.delete_forever,
                                        color: Colors.red.shade700, size: 20),
                                    label: Text('ডিলিট করুন',
                                        style: TextStyle(
                                            color: Colors.red.shade700)),
                                    // সমাধান: সঠিক order_id পাঠানো হচ্ছে
                                    onPressed: () => _showDeleteDialog(
                                        context, order['order_id']),
                                  ),
                                  */
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }),
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'অপেক্ষমাণ';
      case 'shipped':
        return 'শিপমেন্টে';
      case 'delivered':
        return 'ডেলিভার্ড';
      case 'cancelled':
        return 'বাতিল';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /*
  void _showCancelDialog(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('নিশ্চিত করুন'),
          content: Text('আপনি কি সত্যিই অর্ডারটি বাতিল করতে চান?'),
          actions: <Widget>[
            TextButton(
              child: Text('না'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('হ্যাঁ'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                _cancelOrder(context, order);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('স্থায়ীভাবে ডিলিট করুন'),
          content: Text(
              'আপনি কি সত্যিই এই অর্ডারটি স্থায়ীভাবে মুছে ফেলতে চান? এই কাজটি ফিরিয়ে আনা যাবে না।'),
          actions: <Widget>[
            TextButton(
              child: Text('না'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('হ্যাঁ, ডিলিট করুন'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                try {
                  await supabase_flutter.Supabase.instance.client
                      .from('orders')
                      .delete()
                      // সমাধান: সঠিক কলাম 'order_id' ব্যবহার করা হচ্ছে
                      .eq('order_id', orderId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('অর্ডার সফলভাবে ডিলিট করা হয়েছে'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('অর্ডার ডিলিট করা যায়নি: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelOrder(
      BuildContext context, Map<String, dynamic> order) async {
    try {
      // সমাধান: সব ক্যামেলকেস কে স্নেককেসে পরিবর্তন করা হলো
      final String? refererId = order['referer_id'];
      final double bonusGivenToReferrer =
          (order['bonus_given_to_referrer'] as num?)?.toDouble() ?? 0.0;
      final bool useReferBalance = order['use_refer_balance'] ?? false;
      final double referBalanceUsed =
          (order['refer_balance_used'] as num?)?.toDouble() ?? 0.0;

      // ধরে নেওয়া হচ্ছে 'users' টেবিলে 'referBalance' নামে একটি কলাম আছে
      if (refererId != null && bonusGivenToReferrer > 0) {
        final refererDoc = await supabase_flutter.Supabase.instance.client
            .from('users')
            .select('referBalance')
            .eq('id', refererId)
            .single();
        final currentRefererBalance =
            (refererDoc['referBalance'] as num?)?.toDouble() ?? 0.0;
        await supabase_flutter.Supabase.instance.client.from('users').update({
          'referBalance': currentRefererBalance - bonusGivenToReferrer,
        }).eq('id', refererId);
      }

      if (useReferBalance && referBalanceUsed > 0) {
        final currentUser =
            supabase_flutter.Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final userDoc = await supabase_flutter.Supabase.instance.client
              .from('users')
              .select('referBalance')
              .eq('id', currentUser.id)
              .single();
          final currentUserBalance =
              (userDoc['referBalance'] as num?)?.toDouble() ?? 0.0;
          await supabase_flutter.Supabase.instance.client.from('users').update({
            'referBalance': currentUserBalance + referBalanceUsed,
          }).eq('id', currentUser.id);
        }
      }

      await supabase_flutter.Supabase.instance.client.from('orders').update({
        'status': 'cancelled',
        'cancelled_by': 'user', // সমাধান
        'cancelled_at': DateTime.now().toIso8601String(), // সমাধান
        // সমাধান: সঠিক কলাম 'order_id' ব্যবহার করা হচ্ছে
      }).eq('order_id', order['order_id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('অর্ডার বাতিল করা হয়েছে'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('অর্ডার বাতিল করা যায়নি: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  */
}

Widget _buildTransactionDetails(Map<String, dynamic> order) {
  final orderData = order;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // সমাধান: সব ক্যামেলকেস কে স্নেককেসে পরিবর্তন করা হলো
      if (orderData.containsKey('trx_id') &&
          orderData['trx_id'] != null &&
          (orderData['trx_id'] as String).isNotEmpty)
        ListTile(
          title: Text('ট্রানজেকশন আইডি: ${orderData['trx_id']}'),
        ),
      if (orderData.containsKey('user_payment_number') &&
          orderData['user_payment_number'] != null &&
          (orderData['user_payment_number'] as String).isNotEmpty)
        ListTile(
          title: Text('পেমেন্ট নম্বর: ${orderData['user_payment_number']}'),
        ),
    ],
  );
}
