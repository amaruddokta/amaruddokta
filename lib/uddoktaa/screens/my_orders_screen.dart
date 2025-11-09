import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOrdersScreen extends StatelessWidget {
  final String? uid = Supabase.instance.client.auth.currentUser?.id;

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
        body: StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, authSnapshot) {
              if (!authSnapshot.hasData ||
                  authSnapshot.data?.event == AuthChangeEvent.signedOut) {
                return Center(child: Text('আপনি লগইন করেননি'));
              }
              final uid = authSnapshot.data!.session!.user.id;
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('orders')
                    .stream(primaryKey: ['orderId'])
                    .eq('userId', uid)
                    .order('placedAt',
                        ascending: false), // placedAt ব্যবহার করা হচ্ছে
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
                      final orderId = order['orderId'];
                      final grandTotal = order['grandTotal'];
                      final paymentMethod = order['paymentMethod'];
                      final placedAt = DateTime.parse(
                          order['placedAt']); // placedAt ব্যবহার করা হচ্ছে
                      final status = order['status'];
                      final items = List<Map>.from(order['items']);
                      // Get special message if available - using safe access
                      final orderData = order;
                      final specialMessage =
                          orderData.containsKey('specialMessage') == true
                              ? orderData['specialMessage'] ?? ''
                              : '';

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
                              title: Text('ক্রেতার নাম: ${order['userName']}'),
                              subtitle: Text('ফোন: ${order['userPhone']}'),
                            ),
                            ListTile(
                              title: Text('ঠিকানা:'),
                              subtitle: Text(
                                  '${order['location']['house']}, ${order['location']['ward']}, ${order['location']['road']}, ${order['location']['village']}, ${order['location']['union']}, ${order['location']['upazila']}, ${order['location']['district']}, ${order['location']['division']}'),
                            ),
                            // Special Message Section - Added
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
                                  'ডেলিভারি চার্জ: ৳${order['deliveryCharge']}'),
                            ),
                            // Call helper method to build transaction details
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
                                  // Delete Button
                                  TextButton.icon(
                                    icon: Icon(Icons.delete_forever,
                                        color: Colors.red.shade700, size: 20),
                                    label: Text('ডিলিট করুন',
                                        style: TextStyle(
                                            color: Colors.red.shade700)),
                                    onPressed: () => _showDeleteDialog(
                                        context, order['orderId']),
                                  ),
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
                  await Supabase.instance.client
                      .from('orders')
                      .delete()
                      .eq('orderId', orderId);
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
      // Retrieve referral data from the order
      final String? refererId = order['refererId'];
      final double bonusGivenToReferrer =
          (order['bonusGivenToReferrer'] as num?)?.toDouble() ?? 0.0;
      final bool useReferBalance = order['useReferBalance'] ?? false;
      final double referBalanceUsed =
          (order['referBalanceUsed'] as num?)?.toDouble() ?? 0.0;

      // 1. Deduct bonus from referrer if applicable
      if (refererId != null && bonusGivenToReferrer > 0) {
        final refererData = await Supabase.instance.client
            .from('users')
            .select('referBalance')
            .eq('id', refererId)
            .single();
        if (refererData != null) {
          final currentRefererBalance =
              (refererData['referBalance'] as num?)?.toDouble() ?? 0.0;
          await Supabase.instance.client.from('users').update({
            'referBalance': currentRefererBalance - bonusGivenToReferrer,
          }).eq('id', refererId);
        }
      }

      // 2. Refund used referral balance to current user if applicable
      if (useReferBalance && referBalanceUsed > 0) {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final userData = await Supabase.instance.client
              .from('users')
              .select('referBalance')
              .eq('id', currentUser.id)
              .single();
          if (userData != null) {
            final currentUserBalance =
                (userData['referBalance'] as num?)?.toDouble() ?? 0.0;
            await Supabase.instance.client.from('users').update({
              'referBalance': currentUserBalance + referBalanceUsed,
            }).eq('id', currentUser.id);
          }
        }
      }

      // 3. Update order status
      await Supabase.instance.client.from('orders').update({
        'status': 'cancelled',
        'cancelledBy': 'user',
        'cancelledAt': DateTime.now().toIso8601String(),
      }).eq('orderId', order['orderId']);
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
}

// Helper method to build the transaction and payment details
Widget _buildTransactionDetails(Map<String, dynamic> order) {
  final orderData = order;
  if (orderData == null) {
    return SizedBox.shrink(); // Return an empty widget if orderData is null
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (orderData.containsKey('trxId') &&
          orderData['trxId'] != null &&
          (orderData['trxId'] as String).isNotEmpty)
        ListTile(
          title: Text('ট্রানজেকশন আইডি: ${orderData['trxId']}'),
        ),
      if (orderData.containsKey('userPaymentNumber') &&
          orderData['userPaymentNumber'] != null &&
          (orderData['userPaymentNumber'] as String).isNotEmpty)
        ListTile(
          title: Text('পেমেন্ট নম্বর: ${orderData['userPaymentNumber']}'),
        ),
    ],
  );
}
