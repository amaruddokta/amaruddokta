import 'dart:async';
import 'package:get/get.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/offer_model.dart';

class AdminOfferControllerr extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  RxList<Offer> offers = <Offer>[].obs;
  RxBool isLoading = true.obs;
  Rx<Offer?> selectedOfferForEdit = Rx<Offer?>(null);
  Timer? _timer;
  StreamSubscription<List<Map<String, dynamic>>>? _offersSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchOffers();
    // প্রতি মিনিটে মেয়াদোত্তীর্ণ অফার চেক করার জন্য টাইমার সেটআপ
    _timer =
        Timer.periodic(const Duration(minutes: 1), (_) => checkExpiredOffers());
  }

  @override
  void onClose() {
    _offersSubscription?.cancel();
    _timer?.cancel();
    super.onClose();
  }

  void clearSelectedOffer() {
    selectedOfferForEdit.value = null;
  }

  void fetchOffers() {
    isLoading.value = true;
    // Cancel any existing subscription
    _offersSubscription?.cancel();

    try {
      _offersSubscription = _supabase
          .from('offers')
          .stream(primaryKey: ['id'])
          .order('endTime', ascending: true)
          .listen(
            (data) {
              // Clear existing offers before adding new ones
              offers.clear();

              if (data.isEmpty) {
                isLoading.value = false;
                return;
              }

              for (var item in data) {
                try {
                  offers.add(Offer.fromSupabase(item));
                } catch (e) {
                  print('Error parsing document ${item['id']}: $e');
                }
              }

              isLoading.value = false;
              checkExpiredOffers();
            },
            onError: (error) {
              print('Error fetching offers: $error');
              isLoading.value = false;
              Get.snackbar(
                'Error',
                'Failed to fetch offers: $error',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          );
    } catch (e) {
      print('Exception in fetchOffers: $e');
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to setup offer listener: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void checkExpiredOffers() async {
    final now = DateTime.now();
    bool hasExpiredOffers = false;
    List<Offer> updatedOffers = [];

    for (var offer in offers) {
      if (offer.isActive && offer.endTime.isBefore(now)) {
        // Supabase এ আপডেট করুন
        await _supabase
            .from('offers')
            .update({'isActive': false}).eq('id', offer.id);
        hasExpiredOffers = true;

        // লোকাল লিস্টেও আপডেট করুন
        updatedOffers.add(Offer(
          id: offer.id,
          name: offer.name,
          details: offer.details,
          imageUrl: offer.imageUrl,
          company: offer.company,
          originalPrice: offer.originalPrice,
          unit: offer.unit,
          discountPercentage: offer.discountPercentage,
          stock: offer.stock,
          colors: offer.colors,
          size: offer.size,
          category: offer.category,
          subItemName: offer.subItemName,
          isActive: false, // মেয়াদোত্তীর্ণ হলে false সেট করুন
          endTime: offer.endTime,
        ));
      }
    }

    // যদি মেয়াদোত্তীর্ণ অফার থাকে, তাহলে লোকাল লিস্ট আপডেট করুন
    if (hasExpiredOffers) {
      for (var updatedOffer in updatedOffers) {
        int index = offers.indexWhere((o) => o.id == updatedOffer.id);
        if (index != -1) {
          offers[index] = updatedOffer;
        }
      }
      offers.refresh(); // UI আপডেট করতে
    }
  }

  Future<void> addOffer(Offer offer) async {
    try {
      // অফারটি মেয়াদোত্তীর্ণ কিনা চেক করুন
      final now = DateTime.now();
      final isExpired = offer.endTime.isBefore(now);

      // সঠিক isActive স্ট্যাটাস সহ অফার যোগ করুন
      final newOffer = Offer(
        id: '', // Firestore আইডি এসাইন করবে
        name: offer.name,
        details: offer.details,
        imageUrl: offer.imageUrl,
        company: offer.company,
        originalPrice: offer.originalPrice,
        unit: offer.unit,
        discountPercentage: offer.discountPercentage,
        stock: offer.stock,
        colors: offer.colors,
        size: offer.size,
        category: offer.category,
        subItemName: offer.subItemName,
        isActive: isExpired
            ? false
            : offer.isActive, // মেয়াদোত্তীর্ণ হলে false সেট করুন
        endTime: offer.endTime,
      );

      await _supabase.from('offers').insert(newOffer.toSupabase());
      Get.snackbar('Success', 'Offer added successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add offer: $e');
    }
  }

  Future<void> updateOffer(Offer offer) async {
    try {
      // অফারটি মেয়াদোত্তীর্ণ কিনা চেক করুন
      final now = DateTime.now();
      final isExpired = offer.endTime.isBefore(now);

      // সঠিক isActive স্ট্যাটাস সহ অফার আপডেট করুন
      final updatedOffer = Offer(
        id: offer.id,
        name: offer.name,
        details: offer.details,
        imageUrl: offer.imageUrl,
        company: offer.company,
        originalPrice: offer.originalPrice,
        unit: offer.unit,
        discountPercentage: offer.discountPercentage,
        stock: offer.stock,
        colors: offer.colors,
        size: offer.size,
        category: offer.category,
        subItemName: offer.subItemName,
        isActive: isExpired
            ? false
            : offer.isActive, // মেয়াদোত্তীর্ণ হলে false সেট করুন
        endTime: offer.endTime,
      );

      await _supabase
          .from('offers')
          .update(updatedOffer.toSupabase())
          .eq('id', offer.id);
      Get.snackbar('Success', 'Offer updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update offer: $e');
    }
  }

  // NEW METHOD: Update only the end date of an offer
  Future<void> updateOfferDate(String offerId, DateTime newEndTime) async {
    try {
      // Check if the new end time is expired
      final now = DateTime.now();
      final isExpired = newEndTime.isBefore(now);

      // Update the end time and isActive status if needed
      await _supabase.from('offers').update({
        'endTime': newEndTime.toIso8601String(),
        'isActive': isExpired ? false : true, // Only update if expired
      }).eq('id', offerId);

      // লোকাল লিস্টেও আপডেট করুন
      int index = offers.indexWhere((o) => o.id == offerId);
      if (index != -1) {
        final updatedOffer = Offer(
          id: offers[index].id,
          name: offers[index].name,
          details: offers[index].details,
          imageUrl: offers[index].imageUrl,
          company: offers[index].company,
          originalPrice: offers[index].originalPrice,
          unit: offers[index].unit,
          discountPercentage: offers[index].discountPercentage,
          stock: offers[index].stock,
          colors: offers[index].colors,
          size: offers[index].size,
          category: offers[index].category,
          subItemName: offers[index].subItemName,
          isActive: isExpired ? false : offers[index].isActive,
          endTime: newEndTime,
        );
        offers[index] = updatedOffer;
        offers.refresh(); // UI আপডেট করতে
      }

      Get.snackbar(
        'Success',
        'Offer end date updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update offer date: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      rethrow;
    }
  }

  Future<void> deleteOffer(String offerId) async {
    try {
      // 1. Fetch the offer to get the image URL
      final offerData = await _supabase
          .from('offers')
          .select('imageUrl')
          .eq('id', offerId)
          .single();
      if (offerData == null) {
        Get.snackbar('Error', 'Offer not found!');
        return;
      }
      final offer = Offer.fromSupabase(offerData);

      // 2. Delete the image from Supabase Storage
      if (offer.imageUrl.isNotEmpty) {
        try {
          final fileName = offer.imageUrl.split('/').last;
          await _supabase.storage.from('offers').remove([fileName]);
          print('Image deleted from Supabase Storage: ${offer.imageUrl}');
        } catch (e) {
          print('Error deleting image from Supabase Storage: $e');
          // Don't rethrow, proceed to delete Supabase document even if image deletion fails
          Get.snackbar('Warning', 'Failed to delete image from storage: $e',
              snackPosition: SnackPosition.BOTTOM);
        }
      }

      // 3. Delete the Supabase document
      await _supabase.from('offers').delete().eq('id', offerId);
      Get.snackbar('Success', 'Offer deleted successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete offer: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
