import 'package:amar_uddokta/uddoktaa/widgets/label_service.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class OrderController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LabelService labelService = LabelService();

  RxList<OrderModel> allOrders = <OrderModel>[].obs;
  RxList<OrderModel> filteredOrders = <OrderModel>[].obs;
  RxList<OrderModel> todayOrders = <OrderModel>[].obs;
  RxString filterStatus = ''.obs;
  RxString filterPaymentStatus = ''.obs;
  Rx<DateTime?> filterDate = Rx<DateTime?>(null);
  RxString searchQuery = ''.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load labels when controller initializes
    labelService.loadLabels();
    fetchOrders();
  }

  void fetchOrders() {
    isLoading.value = true;
    try {
      _supabase
          .from('orders')
          .stream(primaryKey: ['orderId'])
          .order('placedAt', ascending: false)
          .execute()
          .listen(
            (data) {
              allOrders.value =
                  data.map((map) => OrderModel.fromMap(map)).toList();
              applyFilters();
              fetchTodayOrders();
              isLoading.value = false;
            },
            onError: (error) {
              print('Error in order stream: $error');
              Get.snackbar('Error', 'Failed to load orders: $error');
              isLoading.value = false;
            },
          );
    } catch (e) {
      print('Error fetching orders: $e');
      Get.snackbar('Error', 'Failed to load orders: $e');
      isLoading.value = false;
    }
  }

  void fetchTodayOrders() {
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    todayOrders.value = allOrders.where((order) {
      return order.placedAt.isAfter(todayStart) && // placedAt ব্যবহার করা হচ্ছে
          order.placedAt.isBefore(todayEnd);
    }).toList();
  }

  void applyFilters() {
    List<OrderModel> tempOrders = List.from(allOrders);

    // Date filter
    if (filterDate.value != null) {
      DateTime selectedDate = filterDate.value!;
      DateTime startDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      DateTime endDate = startDate.add(const Duration(days: 1));
      tempOrders = tempOrders.where((order) {
        return order.placedAt
                .isAfter(startDate) && // placedAt ব্যবহার করা হচ্ছে
            order.placedAt.isBefore(endDate);
      }).toList();
    }

    // Status filter
    if (filterStatus.value.isNotEmpty) {
      tempOrders = tempOrders
          .where((order) => order.status == filterStatus.value)
          .toList();
    }

    // Payment status filter
    if (filterPaymentStatus.value.isNotEmpty) {
      tempOrders = tempOrders
          .where((order) => order.paymentStatus == filterPaymentStatus.value)
          .toList();
    }

    // Search query filter
    if (searchQuery.value.isNotEmpty) {
      tempOrders = tempOrders.where((order) {
        return order.userName
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase()) ||
            order.orderId
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase());
      }).toList();
    }

    filteredOrders.value = tempOrders;

    // Update today's orders only if no date filter is applied
    if (filterDate.value == null) {
      fetchTodayOrders();
    } else {
      todayOrders.clear();
    }
  }

  void updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus}).eq('orderId', orderId);
    } catch (e) {
      print('Error updating order status: $e');
      Get.snackbar('Error', 'Failed to update status: $e');
    }
  }

  void updatePaymentStatus(String orderId, bool isSuccess) async {
    try {
      String newStatus = isSuccess ? 'success' : 'failed';
      await _supabase.from('orders').update({
        'paymentStatus': newStatus,
      }).eq('orderId', orderId);
    } catch (e) {
      print('Error updating payment status: $e');
      Get.snackbar('Error', 'Failed to update payment status: $e');
    }
  }

  void updateOrderStatusWithDetails(
      String orderId, Map<String, dynamic> updateData) async {
    try {
      await _supabase.from('orders').update(updateData).eq('orderId', orderId);
    } catch (e) {
      print('Error updating order status: $e');
      Get.snackbar('Error', 'Failed to update status: $e');
    }
  }

  void clearFilters() {
    filterStatus.value = '';
    filterPaymentStatus.value = '';
    filterDate.value = null;
    searchQuery.value = '';
    applyFilters();
  }
}
