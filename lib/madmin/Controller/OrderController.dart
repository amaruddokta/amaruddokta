import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart'; // Assuming OrderModel can be constructed from a Map
import '../widgets/label_service.dart'; // Corrected import path for LabelService

class OrderController extends GetxController {
  // Initialize Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;
  final LabelService labelService =
      LabelService(); // Assuming LabelService is still used

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
    labelService.loadLabels(); // Assuming this method is still relevant
    fetchOrders();
  }

  // Fetch orders from Supabase
  void fetchOrders() async {
    // Make fetchOrders async
    isLoading.value = true;
    try {
      // Supabase query to fetch orders, ordered by placedAt descending
      // Assuming 'placedAt' is a timestamp column in Supabase
      final response = await _supabase
          .from('orders')
          .select()
          .order('placedAt', ascending: false); // No .then() here

      // Assuming OrderModel has a fromMap constructor
      allOrders.value =
          (response as List<Map<String, dynamic>>) // Explicitly cast
              .map((doc) => OrderModel.fromMap(doc))
              .toList();
      applyFilters();
      fetchTodayOrders();
      isLoading.value = false;
    } catch (e) {
      print('Error fetching orders: $e');
      Get.snackbar('Error', 'Failed to load orders: $e');
      isLoading.value = false;
    }
  }

  // Fetch today's orders based on the current allOrders list
  void fetchTodayOrders() {
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    todayOrders.value = allOrders.where((order) {
      // Assuming order.placedAt is a DateTime object
      return order.placedAt.isAfter(todayStart) &&
          order.placedAt.isBefore(todayEnd);
    }).toList();
  }

  // Apply filters to the fetched orders
  void applyFilters() {
    List<OrderModel> tempOrders = List.from(allOrders);

    // Date filter
    if (filterDate.value != null) {
      DateTime selectedDate = filterDate.value!;
      DateTime startDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      DateTime endDate = startDate.add(const Duration(days: 1));
      tempOrders = tempOrders.where((order) {
        // Assuming order.placedAt is a DateTime object
        return order.placedAt.isAfter(startDate) &&
            order.placedAt.isBefore(endDate);
      }).toList();
    }

    // Status filter
    if (filterStatus.value.isNotEmpty && filterStatus.value != 'All') {
      tempOrders = tempOrders
          .where((order) => order.status == filterStatus.value)
          .toList();
    }

    // Payment status filter
    if (filterPaymentStatus.value.isNotEmpty &&
        filterPaymentStatus.value != 'All') {
      tempOrders = tempOrders
          .where((order) => order.paymentStatus == filterPaymentStatus.value)
          .toList();
    }

    // Search query filter
    if (searchQuery.value.isNotEmpty) {
      tempOrders = tempOrders.where((order) {
        // Assuming userName and orderId are String properties
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

  // Update order status in Supabase
  void updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({'status': newStatus}).eq(
              'orderId', orderId); // Use eq for primary key

      if (response.error == null) {
        // If update is successful, refresh the orders list to reflect changes
        fetchOrders(); // Re-fetch all orders to update UI
      } else {
        print('Supabase update error: ${response.error!.message}');
        Get.snackbar(
            'Error', 'Failed to update status: ${response.error!.message}');
      }
    } catch (e) {
      print('Error updating order status: $e');
      Get.snackbar('Error', 'Failed to update status: $e');
    }
  }

  // Update payment status in Supabase
  void updatePaymentStatus(String orderId, bool isSuccess) async {
    try {
      String newStatus = isSuccess ? 'success' : 'failed';
      final response = await _supabase.from('orders').update({
        'paymentStatus': newStatus,
      }).eq('orderId', orderId); // Use eq for primary key

      if (response.error == null) {
        // If update is successful, refresh the orders list to reflect changes
        fetchOrders(); // Re-fetch all orders to update UI
      } else {
        print('Supabase update error: ${response.error!.message}');
        Get.snackbar('Error',
            'Failed to update payment status: ${response.error!.message}');
      }
    } catch (e) {
      print('Error updating payment status: $e');
      Get.snackbar('Error', 'Failed to update payment status: $e');
    }
  }

  // Update order status with more details in Supabase
  void updateOrderStatusWithDetails(
      String orderId, Map<String, dynamic> updateData) async {
    try {
      final response = await _supabase
          .from('orders')
          .update(updateData)
          .eq('orderId', orderId); // Use eq for primary key

      if (response.error == null) {
        // If update is successful, refresh the orders list to reflect changes
        fetchOrders(); // Re-fetch all orders to update UI
      } else {
        print('Supabase update error: ${response.error!.message}');
        Get.snackbar(
            'Error', 'Failed to update status: ${response.error!.message}');
      }
    } catch (e) {
      print('Error updating order status: $e');
      Get.snackbar('Error', 'Failed to update status: $e');
    }
  }

  // Clear all filters
  void clearFilters() {
    filterStatus.value = 'All'; // Reset to 'All' to match UI
    filterPaymentStatus.value = 'All'; // Reset to 'All' to match UI
    filterDate.value = null;
    searchQuery.value = '';
    applyFilters(); // Re-apply filters to show all orders
  }
}
