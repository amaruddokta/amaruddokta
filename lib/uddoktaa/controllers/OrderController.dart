// lib/controllers/OrderController.dart

import 'package:get/get.dart';
import 'package:amar_uddokta/madmin/models/order_model.dart';
import 'package:amar_uddokta/madmin/services/supabase_service.dart'; // Import SupabaseService
import 'package:amar_uddokta/madmin/widgets/label_service.dart';
import 'package:get/get.dart'; // Ensure Get is imported for GetxController

class OrderController extends GetxController {
  final SupabaseService _supabaseService =
      SupabaseService(); // Use SupabaseService
  final LabelService labelService = LabelService();

  RxList<OrderModel> allOrders = <OrderModel>[].obs;
  RxList<OrderModel> todayOrders = <OrderModel>[].obs;
  RxList<OrderModel> filteredOrders = <OrderModel>[].obs;

  RxString searchQuery = ''.obs;
  RxString filterStatus = ''.obs;
  RxString filterPaymentStatus = ''.obs;
  Rx<DateTime?> filterDate = Rx<DateTime?>(null);
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      // SupabaseService থেকে অর্ডার আনুন
      _supabaseService.getOrders().listen((orders) {
        allOrders.value = orders;

        // আজকের অর্ডার ফিল্টার করা হচ্ছে
        final today = DateTime.now();
        todayOrders.value = allOrders.where((order) {
          return order.placedAt.year == today.year &&
              order.placedAt.month == today.month &&
              order.placedAt.day == today.day;
        }).toList();

        applyFilters();
      });
    } catch (e) {
      print('Error fetching orders: $e');
      Get.snackbar('Error', 'Failed to fetch orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    filteredOrders.value = allOrders.where((order) {
      // সার্চ কোয়ের জন্য ফিল্টার
      if (searchQuery.value.isNotEmpty &&
          !order.userName
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) &&
          !order.orderId
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase())) {
        return false;
      }

      // স্ট্যাটাস ফিল্টার
      if (filterStatus.value.isNotEmpty && order.status != filterStatus.value) {
        return false;
      }

      // পেমেন্ট স্ট্যাটাস ফিল্টার
      if (filterPaymentStatus.value.isNotEmpty &&
          order.paymentStatus != filterPaymentStatus.value) {
        return false;
      }

      // তারিখ ফিল্টার
      if (filterDate.value != null) {
        final orderDate = DateTime(
            order.placedAt.year, order.placedAt.month, order.placedAt.day);
        final filter = DateTime(filterDate.value!.year, filterDate.value!.month,
            filterDate.value!.day);
        if (orderDate.isBefore(filter) || orderDate.isAfter(filter)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> updateOrderStatusWithDetails(
      String orderId, Map<String, dynamic> updateData) async {
    try {
      final existingOrder =
          allOrders.firstWhere((order) => order.orderId == orderId);
      final updatedOrder = existingOrder.copyWith(
        status: updateData['status'],
        cancelledAt: updateData['cancelled_at'] != null
            ? DateTime.parse(updateData['cancelled_at'])
            : null,
        cancelledBy: updateData['cancelled_by'],
      );
      await _supabaseService.updateOrder(updatedOrder);
      Get.snackbar('Success', 'Order status updated successfully');
    } catch (e) {
      print('Error updating order status: $e');
      Get.snackbar('Error', 'Failed to update order status: $e');
    }
  }

  Future<void> updatePaymentStatus(String orderId, bool isSuccess) async {
    try {
      final existingOrder =
          allOrders.firstWhere((order) => order.orderId == orderId);
      final updatedOrder = existingOrder.copyWith(
        paymentStatus: isSuccess ? 'success' : 'pending',
      );
      await _supabaseService.updateOrder(updatedOrder);
      Get.snackbar('Success', 'Payment status updated successfully');
    } catch (e) {
      print('Error updating payment status: $e');
      Get.snackbar('Error', 'Failed to update payment status: $e');
    }
  }
}
