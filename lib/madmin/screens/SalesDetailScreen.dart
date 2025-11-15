// sales_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SalesDetailScreen extends StatelessWidget {
  const SalesDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today =
        DateTime.now().toUtc().add(const Duration(hours: 6)); // BD Time
    final startOfDay = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(title: const Text('আজকের বিক্রির বিস্তারিত')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('orders')
            .stream(primaryKey: ['id'])
            .gte('timestamp', startOfDay.toIso8601String())
            .order('timestamp', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          double totalSales = 0;
          for (var order in orders) {
            totalSales += (order['totalPrice'] ?? 0).toDouble();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'মোট অর্ডার: ${orders.length}\nমোট বিক্রি: ৳${totalSales.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final timestamp =
                        DateTime.parse(order['timestamp']).toLocal();
                    final formattedDate =
                        DateFormat('dd-MM-yyyy hh:mm a').format(timestamp);
                    return ListTile(
                      title: Text('Order ID: ${order['id']}'),
                      subtitle: Text(
                          'Amount: ৳${order['totalPrice']}\nTime: $formattedDate'),
                      trailing: const Icon(Icons.receipt_long),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
