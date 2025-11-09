import 'package:get/get.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';

class CartController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  RxList<CartItem> cartItems = <CartItem>[].obs;
  String? lastPlacedOrderId;

  // ✅ Cart total calculation getter
  double get total {
    return cartItems.fold<double>(0, (sum, item) {
      final price = item.price * (100 - item.discountPercentage) / 100;
      return sum + price * item.quantity;
    });
  }

  // ✅ Get delivery fee based on location
  Future<double> getDeliveryFee(
      String division, String district, String upazila) async {
    try {
      // First try to get specific fee for upazila
      final upazilaResponse = await _supabase
          .from('delivery_fees')
          .select('fee')
          .eq('division', division)
          .eq('district', district)
          .eq('upazila', upazila)
          .maybeSingle();
      if (upazilaResponse != null) {
        return double.parse(upazilaResponse['fee'].toString());
      }
      // If not found, try to get fee for district
      final districtResponse = await _supabase
          .from('delivery_fees')
          .select('fee')
          .eq('division', division)
          .eq('district', district)
          .isFilter('upazila', null)
          .maybeSingle();
      if (districtResponse != null) {
        return double.parse(districtResponse['fee'].toString());
      }
      // If not found, try to get fee for division
      final divisionResponse = await _supabase
          .from('delivery_fees')
          .select('fee')
          .eq('division', division)
          .isFilter('district', null)
          .isFilter('upazila', null)
          .maybeSingle();
      if (divisionResponse != null) {
        return double.parse(divisionResponse['fee'].toString());
      }
      // If no specific fee found, return default fee
      return 30.0;
    } catch (e) {
      print('Error getting delivery fee: $e');
      return 30.0; // Default fee in case of error
    }
  }

  // রেফারেল কোড দিয়ে রেফারারের তথ্য পাওয়ার ফাংশন
  Future<Map<String, dynamic>?> getRefererData(String referCode) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('referCode', referCode)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting referer data: $e');
      return null;
    }
  }

  // রেফারারের ব্যালেন্স বৃদ্ধি করার ফাংশন
  Future<bool> updateRefererBalance(String refererId, double bonus) async {
    try {
      final response = await _supabase
          .from('users')
          .select('referBalance')
          .eq('id', refererId)
          .single();
      final data = response;

      if (data != null) {
        final currentBalance =
            (data['referBalance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + bonus;

        await _supabase.from('users').update({
          'referBalance': newBalance,
        }).eq('id', refererId);

        return true;
      }
      return false;
    } catch (e) {
      print('Error updating referer balance: $e');
      return false;
    }
  }

  Future<void> placeOrder({
    required String userName,
    required String userPhone,
    required Map<String, dynamic> userLocation,
    String? userGpsLocation, // ✅ GPS লোকেশন প্যারামিটার
    String specialMessage = '',
    required String paymentMethod,
    required String trxId,
    String? userPaymentNumber,
    required List<CartItem> cartItems,
    String? referCode,
    bool useReferBalance = false,
    double referBalanceUsed = 0.0,
    String? refererId,
    double bonusGivenToReferrer = 0.0,
    String? paymentStatus, // ✅ পেমেন্ট স্ট্যাটাস প্যারামিটার যোগ করা হল
  }) async {
    final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
    final items = cartItems.map((item) => item.toMap()).toList();
    final total = cartItems.fold<double>(0, (sum, item) {
      final price = item.price * (100 - item.discountPercentage) / 100;
      return sum + price * item.quantity;
    });

    // Check if there's any package in the cart
    final hasPackage = cartItems.any((item) => item.isPackage);

    // Get delivery fee based on location if not a package
    double deliveryCharge = 0.0;
    if (!hasPackage) {
      final division = userLocation['division'] ?? '';
      final district = userLocation['district'] ?? '';
      final upazila = userLocation['upazila'] ?? '';
      deliveryCharge = await getDeliveryFee(division, district, upazila);
    }

    // রেফারেল ব্যালেন্স ব্যবহার করলে মোট মূল্য হিসাব করা
    double grandTotal = total + deliveryCharge;
    if (useReferBalance && referBalanceUsed > 0) {
      grandTotal =
          grandTotal > referBalanceUsed ? grandTotal - referBalanceUsed : 0;
    }

    final orderData = {
      'orderId': orderId,
      'userName': userName,
      'userPhone': userPhone,
      'location': userLocation,
      'userGpsLocation': userGpsLocation, // ✅ GPS লোকেশন অর্ডার ডেটাতে
      'specialMessage': specialMessage,
      'items': items,
      'total': total,
      'deliveryCharge': deliveryCharge,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'trxId': trxId,
      'userPaymentNumber': userPaymentNumber ?? '',
      'status': 'pending',
      'paymentStatus': paymentStatus ??
          (paymentMethod == 'Cash on Delivery' ? 'pending' : 'awaiting'),
      'userId': _supabase.auth.currentUser?.id,
      'referCode': referCode,
      'useReferBalance': useReferBalance,
      'referBalanceUsed': referBalanceUsed,
      'refererId': refererId,
      'bonusGivenToReferrer': bonusGivenToReferrer,
    };

    await _supabase.from('orders').insert(orderData);
    lastPlacedOrderId = orderId;
    cartItems.clear();
    update();
  }

  // ✅ Payment Success হলে Supabase-এ update করার Method
  Future<void> markPaymentSuccess(String orderId) async {
    await _supabase
        .from('orders')
        .update({'paymentStatus': 'success'}).eq('orderId', orderId);
  }

  void removeFromCart(String itemId, {String? color, String? size}) {
    cartItems.removeWhere((item) =>
        item.id == itemId && item.color == color && item.size == size);
    update();
  }

  void increaseQuantity(String itemId, {String? color, String? size}) {
    try {
      final item = cartItems.firstWhere((item) =>
          item.id == itemId && item.color == color && item.size == size);
      item.quantity++;
      cartItems.refresh();
    } catch (e) {
      print("Error increasing quantity: $e");
    }
  }

  void decreaseQuantity(String itemId, {String? color, String? size}) {
    final itemIndex = cartItems.indexWhere((item) =>
        item.id == itemId && item.color == color && item.size == size);
    if (itemIndex != -1) {
      if (cartItems[itemIndex].quantity > 1) {
        cartItems[itemIndex].quantity--;
      } else {
        cartItems.removeAt(itemIndex);
      }
      cartItems.refresh();
    }
  }

  void addItemToCart(CartItem item) {
    final itemIndex = cartItems.indexWhere(
        (i) => i.id == item.id && i.color == item.color && i.size == item.size);
    if (itemIndex != -1) {
      // If item with same id, color, and size already exists, just increase the quantity
      cartItems[itemIndex].quantity += item.quantity;
    } else {
      // If item doesn't exist, add it to the cart
      cartItems.add(item);
    }
    update();
  }
}
