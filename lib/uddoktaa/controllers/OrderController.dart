// lib/controllers/OrderController.dart

import 'package:get/get.dart';
import 'package:amar_uddokta/madmin/models/order_model.dart';
import 'package:amar_uddokta/madmin/services/supabase_service.dart';
import 'package:amar_uddokta/uddoktaa/widgets/label_service.dart';
// সমাধান: collection প্যাকেজ থেকে firstWhereOrNull ইম্পোর্ট করুন
import 'package:collection/collection.dart';

class OrderController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService();
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
      _supabaseService.getOrders().listen((orders) {
        allOrders.value = orders;

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
      if (searchQuery.value.isNotEmpty &&
          !order.userName
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) &&
          !order.orderId
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase())) {
        return false;
      }

      if (filterStatus.value.isNotEmpty && order.status != filterStatus.value) {
        return false;
      }

      if (filterPaymentStatus.value.isNotEmpty &&
          order.paymentStatus != filterPaymentStatus.value) {
        return false;
      }

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
      // সমাধান: firstWhere এর পরিবর্তে firstWhereOrNull ব্যবহার করুন
      final existingOrder =
          allOrders.firstWhereOrNull((order) => order.orderId == orderId);

      // যদি অর্ডার না পাওয়া যায়, তাহলে ফাংশনটি এখানেই শেষ করুন
      if (existingOrder == null) {
        print('Error: Order with ID $orderId not found.');
        Get.snackbar('Error', 'Order not found.');
        return;
      }

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
      // সমাধান: firstWhere এর পরিবর্তে firstWhereOrNull ব্যবহার করুন
      final existingOrder =
          allOrders.firstWhereOrNull((order) => order.orderId == orderId);

      // যদি অর্ডার না পাওয়া যায়, তাহলে ফাংশনটি এখানেই শেষ করুন
      if (existingOrder == null) {
        print('Error: Order with ID $orderId not found.');
        Get.snackbar('Error', 'Order not found.');
        return;
      }

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
