import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class AboutController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  RxList<Map<String, dynamic>> aboutList = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAboutList();
  }

  Future<void> fetchAboutList() async {
    try {
      isLoading.value = true;
      final response = await _supabase
          .from('manAbout')
          .select()
          .order('position_order', ascending: true);
      aboutList.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch manAbout data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName =
          'about_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('manAbout').upload(fileName, imageFile);
      return _supabase.storage.from('manAbout').getPublicUrl(fileName);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final fileName = imageUrl.split('/').last;
        await _supabase.storage.from('manAbout').remove([fileName]);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> addAboutData({
    String? manTitle,
    String? manSubtitle,
    String? manRole,
    String? manDescription,
    String? manImageUrl,
  }) async {
    try {
      isLoading.value = true;
      // Get the current count to set the order (new item at the end)
      final count = aboutList.length;
      await _supabase.from('manAbout').insert({
        'manTitle': manTitle,
        'manSubtitle': manSubtitle,
        'manRole': manRole,
        'manDescription': manDescription,
        'manImageUrl': manImageUrl,
        'position_order': count,
      });
      await fetchAboutList();
      Get.snackbar(
        'Success',
        'New About entry added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add about data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAboutData(
    String id, {
    String? manTitle,
    String? manSubtitle,
    String? manRole,
    String? manDescription,
    String? manImageUrl,
    bool shouldDeleteImage = false,
  }) async {
    try {
      isLoading.value = true;
      Map<String, dynamic> updateData = {};
      if (manTitle != null) updateData['manTitle'] = manTitle;
      if (manSubtitle != null) updateData['manSubtitle'] = manSubtitle;
      if (manRole != null) updateData['manRole'] = manRole;
      if (manDescription != null) updateData['manDescription'] = manDescription;
      if (manImageUrl != null) updateData['manImageUrl'] = manImageUrl;

      if (shouldDeleteImage) {
        final response = await _supabase
            .from('manAbout')
            .select('manImageUrl')
            .eq('id', id)
            .single();
        final currentImageUrl = response['manImageUrl'];
        if (currentImageUrl?.isNotEmpty == true) {
          await deleteImage(currentImageUrl);
        }
        updateData['manImageUrl'] = '';
      }

      await _supabase.from('manAbout').update(updateData).eq('id', id);
      await fetchAboutList();
      Get.snackbar(
        'Success',
        'About data updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update about data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAboutData(String id, String? imageUrl) async {
    try {
      isLoading.value = true;
      if (imageUrl?.isNotEmpty == true) {
        await deleteImage(imageUrl!);
      }
      await _supabase.from('manAbout').delete().eq('id', id);

      // After deletion, we need to update the order of the remaining items
      final remainingItems =
          aboutList.where((item) => item['id'] != id).toList();
      await updateOrder(remainingItems);

      Get.snackbar(
        'Success',
        'About entry deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete about data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // New method to update the order of items
  Future<void> updateOrder(List<Map<String, dynamic>> items) async {
    try {
      for (int i = 0; i < items.length; i++) {
        await _supabase
            .from('manAbout')
            .update({'position_order': i}).eq('id', items[i]['id']);
      }
      await fetchAboutList(); // Refresh the list
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Method to reorder items
  Future<void> reorderItems(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = aboutList.removeAt(oldIndex);
      aboutList.insert(newIndex, item);

      // Update order field for all items
      for (int i = 0; i < aboutList.length; i++) {
        await _supabase
            .from('manAbout')
            .update({'position_order': i}).eq('id', aboutList[i]['id']);
      }
      await fetchAboutList(); // Refresh the list
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reorder items: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
