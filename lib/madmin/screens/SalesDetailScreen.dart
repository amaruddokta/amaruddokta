// sales_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesDetailScreen extends StatelessWidget {
  const SalesDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today =
        DateTime.now().toUtc().add(const Duration(hours: 6)); // BD Time
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    return Scaffold(
      appBar: AppBar(title: const Text('আজকের বিক্রির বিস্তারিত')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('orders')
            .stream(primaryKey: ['orderId'])
            .gte('placedAt', startOfDay) // Use placedAt for filtering
            .execute()
            .map((data) => data),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!;
          double totalSales = 0;
          for (var order in docs) {
            totalSales += (order['grandTotal'] as num?)?.toDouble() ??
                0.0; // Use grandTotal
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'মোট অর্ডার: ${docs.length}\nমোট বিক্রি: ৳${totalSales.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final order = docs[index];
                    final timestamp = DateTime.parse(order['placedAt'])
                        .toLocal(); // Use placedAt
                    final formattedDate =
                        DateFormat('dd-MM-yyyy hh:mm a').format(timestamp);
                    return ListTile(
                      title: Text('Order ID: ${order['orderId']}'),
                      subtitle: Text(
                          'Amount: ৳${(order['grandTotal'] as num?)?.toDouble() ?? 0.0}\nTime: $formattedDate'),
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
