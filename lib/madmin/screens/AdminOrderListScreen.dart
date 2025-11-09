import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controller/OrderController.dart';

class AdminOrderListScreen extends StatelessWidget {
  const AdminOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OrderController orderController = Get.put(OrderController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: () {
              // Note: PDF export logic needs to be web-compatible.
              // The previous implementation using 'dart:io' and 'path_provider' will not work on web.
              // A web-specific implementation is required.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('PDF export for web is not implemented yet.')),
              );
            },
          )
        ],
      ),
      body: Obx(() {
        if (orderController.filteredOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: orderController.filteredOrders.length,
          itemBuilder: (context, index) {
            final order = orderController.filteredOrders[index];
            return ListTile(
              title: Text('Order ID: ${order.orderId}'),
              subtitle:
                  Text('User: ${order.userName}\nStatus: ${order.status}'),
              isThreeLine: true,
              onTap: () {
                // Optional: Navigate to order details screen
              },
            );
          },
        );
      }),
    );
  }
}
