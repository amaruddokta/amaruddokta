import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDeliveryFeeController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  RxList<Map<String, dynamic>> deliveryFees = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDeliveryFees();
  }

  Future<void> fetchDeliveryFees() async {
    try {
      final response = await _supabase.from('delivery_fees').select();
      deliveryFees.value = response.map((data) {
        return {'id': data['id'], ...data};
      }).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch delivery fees: $e');
    }
  }

  Future<void> addDeliveryFee(Map<String, dynamic> feeData) async {
    try {
      await _supabase.from('delivery_fees').insert(feeData);
      fetchDeliveryFees();
      Get.snackbar('Success', 'Delivery fee added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add delivery fee: $e');
    }
  }

  Future<void> updateDeliveryFee(
      String id, Map<String, dynamic> feeData) async {
    try {
      await _supabase.from('delivery_fees').update(feeData).eq('id', id);
      fetchDeliveryFees();
      Get.snackbar('Success', 'Delivery fee updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update delivery fee: $e');
    }
  }

  Future<void> deleteDeliveryFee(String id) async {
    try {
      await _supabase.from('delivery_fees').delete().eq('id', id);
      fetchDeliveryFees();
      Get.snackbar('Success', 'Delivery fee deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete delivery fee: $e');
    }
  }
}
