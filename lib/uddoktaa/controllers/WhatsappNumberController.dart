import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WhatsappNumberController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  RxString whatsappNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWhatsappNumber();
  }

  Future<void> fetchWhatsappNumber() async {
    try {
      final response = await _supabase
          .from('whatsappNumbers')
          .select('number')
          .order('timestamp', ascending: false)
          .limit(1)
          .single();

      whatsappNumber.value = response['number'] as String;
        } catch (e) {
      Get.snackbar('Error', 'Failed to fetch WhatsApp number: $e');
      whatsappNumber.value = ''; // Fallback on error
    }
  }
}
