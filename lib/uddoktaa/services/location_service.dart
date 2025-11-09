import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  // বর্তমান লোকেশন পাওয়ার মেথড
  static Future<String?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // লোকেশন সার্ভিস চেক করা
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('ত্রুটি', 'লোকেশন সার্ভিস ডিসেবল আছে।');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('ত্রুটি', 'লোকেশন পারমিশন দেওয়া হয়নি।');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('ত্রুটি', 'লোকেশন পারমিশন স্থায়ীভাবে বাতিল করা হয়েছে।');
        return null;
      }

      // বর্তমান লোকেশন পাওয়া
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      
      return googleMapsUrl;
    } catch (e) {
      Get.snackbar('ত্রুটি', 'লোকেশন পেতে সমস্যা হয়েছে: $e');
      return null;
    }
  }

  static Future<void> launchMapUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('ত্রুটি', 'ম্যাপ খুলতে সমস্যা হয়েছে।');
    }
  }
}
