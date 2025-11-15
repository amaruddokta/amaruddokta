// lib/controllers/AdminDeliveryFeeController.dart

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDeliveryFeeController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  RxList<Map<String, dynamic>> deliveryFees = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDeliveryFees();
  }

  Future<void> fetchDeliveryFees() async {
    isLoading.value = true;
    try {
      final response = await _supabase
          .from('delivery_fees')
          .select('*')
          .order('division', ascending: true)
          .order('district', ascending: true)
          .order('upazila', ascending: true);

      if (response != null) {
        deliveryFees.value = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error fetching delivery fees: $e');
      Get.snackbar('Error', 'Failed to fetch delivery fees: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addDeliveryFee({
    required String division,
    String? district,
    String? upazila,
    required double fee,
  }) async {
    try {
      await _supabase.from('delivery_fees').insert({
        'division': division,
        'district': district,
        'upazila': upazila,
        'fee': fee,
      });

      fetchDeliveryFees();
      Get.snackbar('Success', 'Delivery fee added successfully');
    } catch (e) {
      print('Error adding delivery fee: $e');
      Get.snackbar('Error', 'Failed to add delivery fee: $e');
    }
  }

  Future<void> updateDeliveryFee({
    required String id,
    required String division,
    String? district,
    String? upazila,
    required double fee,
  }) async {
    try {
      await _supabase.from('delivery_fees').update({
        'division': division,
        'district': district,
        'upazila': upazila,
        'fee': fee,
      }).eq('id', id);

      fetchDeliveryFees();
      Get.snackbar('Success', 'Delivery fee updated successfully');
    } catch (e) {
      print('Error updating delivery fee: $e');
      Get.snackbar('Error', 'Failed to update delivery fee: $e');
    }
  }

  Future<void> deleteDeliveryFee(String id) async {
    try {
      await _supabase.from('delivery_fees').delete().eq('id', id);

      fetchDeliveryFees();
      Get.snackbar('Success', 'Delivery fee deleted successfully');
    } catch (e) {
      print('Error deleting delivery fee: $e');
      Get.snackbar('Error', 'Failed to delete delivery fee: $e');
    }
  }
}
