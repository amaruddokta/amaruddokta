// ignore_for_file: unused_local_variable, unnecessary_string_escapes

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amar_uddokta/uddoktaa/controllers/cart_controller.dart';
import 'package:amar_uddokta/uddoktaa/screens/my_orders_screen.dart';
import 'package:amar_uddokta/uddoktaa/screens/registration_screen.dart'
    as dokane;
import 'package:amar_uddokta/uddoktaa/widgets/background_container.dart';
import 'package:amar_uddokta/uddoktaa/services/location_service.dart'; // ✅ লোকেশন সার্ভিস ইম্পোর্ট
import 'package:amar_uddokta/uddoktaa/data/location_data.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartController cartController;
  String selectedPaymentMethod = 'Cash on Delivery';
  final trxIdController = TextEditingController();
  final userPaymentNumberController = TextEditingController();
  bool useNewAddress = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _roadController = TextEditingController();
  final TextEditingController _specialMessageController =
      TextEditingController();
  final TextEditingController _referCodeController = TextEditingController();

  // রিঅ্যাক্টিভ ভেরিয়েবল হিসেবে ডিক্লেয়ার করা হল
  final RxBool _useReferBalance = false.obs;
  final RxDouble _userReferBalance = 0.0.obs;
  final RxBool _isReferCodeValid = true.obs;
  final RxString _userReferCode = ''.obs;
  final RxString _currentRefererId = ''.obs;
  final RxDouble _currentBonusGivenToReferrer = 0.0.obs;

  // রিঅ্যাক্টিভ ভেরিয়েবল হিসেবে ডিক্লেয়ার করা হল
  final RxString _selectedDivision = ''.obs;
  final RxString _selectedDistrict = ''.obs;
  final RxString _selectedUpazila = ''.obs;
  final RxString _selectedUnion = ''.obs;

  final Rx<Map<String, dynamic>> userData = Rx<Map<String, dynamic>>({});

  // নতুন ভেরিয়েবল যোগ করা হল
  final RxBool _isUddokta = false.obs;
  final RxBool _isLoading = true.obs;
  final RxInt _cartItemsVersion =
      0.obs; // কার্ট আইটেম পরিবর্তন ট্র্যাক করার জন্য

  @override
  void initState() {
    super.initState();
    debugPrint('CartScreen initState called');

    // Initialize the controller safely
    try {
      cartController = Get.find<CartController>();
    } catch (e) {
      cartController = Get.put(CartController());
    }

    // কার্ট আইটেম পরিবর্তন লিসেন করা হল
    ever(cartController.cartItems, (_) {
      _cartItemsVersion.value++;
    });

    _checkUserType().then((_) {
      _loadUserData().then((_) {
        debugPrint('CartScreen _loadUserData completed');
        _updateDeliveryFee();
        // _loadUserReferBalance();
      });
    });
  }

  // নতুন মেথড যোগ করা হল
  Future<void> _checkUserType() async {
    _isLoading.value = true;

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // চেক করা হচ্ছে বর্তমান ইউজার উদ্যোক্তা কিনা
        final uddoktaDoc = await Supabase.instance.client
            .from('u-users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        _isUddokta.value = uddoktaDoc != null;
      } catch (e) {
        print('Error checking user type: $e');
      }
    } else {
      _isUddokta.value = false;
    }

    _isLoading.value = false;
  }

  Future<void> _loadUserData() async {
    debugPrint('CartScreen _loadUserData started');
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !_isUddokta.value) {
      // শুধুমাত্র সাধারণ ইউজারদের জন্য ডাটা লোড করা হবে
      debugPrint('CartScreen _loadUserData: User is logged in: ${user.id}');
      final userDoc = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      debugPrint(
          'CartScreen _loadUserData: userDoc exists: ${userDoc != null}');

      final data = userDoc ?? {};
      userData.value =
          data; // userData will be empty map if userDoc doesn't exist

      if (data.isNotEmpty) {
        debugPrint('CartScreen _loadUserData: userData loaded: $data');
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _selectedDivision.value = data['division'] ?? '';
        _selectedDistrict.value = data['district'] ?? '';
        _selectedUpazila.value = data['upazila'] ?? '';
        _selectedUnion.value = data['union'] ?? '';
        _villageController.text = data['village'] ?? '';
        _wardController.text = data['ward'] ?? '';
        _houseController.text = data['house'] ?? '';
        _roadController.text = data['road'] ?? '';
        _userReferCode.value = data['referCode'] ?? '';
      } else {
        debugPrint(
            'CartScreen _loadUserData: userData is empty (profile incomplete)');
      }
    } else {
      debugPrint(
          'CartScreen _loadUserData: User is NOT logged in or is Uddokta');
      userData.value =
          {}; // Ensure userData is empty map if no user is logged in or is Uddokta
    }
  }

  // Future<void> _loadUserReferBalance() async {
  //   if (_isUddokta.value) {
  //     return; // উদ্যোক্তাদের জন্য রেফার ব্যালেন্স লোড করা হবে না
  //   }

  //   final user = Supabase.instance.client.auth.currentUser;
  //   if (user != null) {
  //     final userDoc = await Supabase.instance.client
  //         .from('users')
  //         .select('referBalance')
  //         .eq('id', user.id)
  //         .maybeSingle();
  //     if (userDoc == null) {
  //       _userReferBalance.value = 0.0;
  //       return;
  //     }
  //     final data = userDoc;
  //     final dynamic balance = data['referBalance'];
  //     if (balance is String) {
  //       _userReferBalance.value = double.tryParse(balance) ?? 0.0;
  //     } else if (balance is num) {
  //       _userReferBalance.value = balance.toDouble();
  //     } else {
  //       _userReferBalance.value = 0.0;
  //     }
  //   }
  // }

  // Future<void> _applyReferCode() async {
  //   if (_isUddokta.value) return; // উদ্যোক্তাদের জন্য রেফার কোড প্রযোজ্য নয়

  //   final referCode = _referCodeController.text.trim();
  //   if (referCode.isEmpty) {
  //     _isReferCodeValid.value = false;
  //     Get.snackbar('ত্রুটি', 'রেফারেল কোড দিন',
  //         snackPosition: SnackPosition.BOTTOM);
  //     return;
  //   }

  //   if (referCode == _userReferCode.value) {
  //     _isReferCodeValid.value = false;
  //     Get.snackbar('ত্রুটি', 'আপনি নিজের রেফারেল কোড ব্যবহার করতে পারবেন না',
  //         snackPosition: SnackPosition.BOTTOM);
  //     return;
  //   }

  //   final response = await Supabase.instance.client
  //       .from('users')
  //       .select()
  //       .eq('referCode', referCode);

  //   if (response.isEmpty) {
  //     _isReferCodeValid.value = false;
  //     Get.snackbar('ত্রুটি', 'অবৈধ রেফারেল কোড',
  //         snackPosition: SnackPosition.BOTTOM);
  //     return;
  //   }

  //   final currentUser = Supabase.instance.client.auth.currentUser;
  //   if (currentUser != null && response.first['id'] == currentUser.id) {
  //     _isReferCodeValid.value = false;
  //     Get.snackbar('ত্রুটি', 'আপনি নিজের রেফারেল কোড ব্যবহার করতে পারবেন না',
  //         snackPosition: SnackPosition.BOTTOM);
  //     return;
  //   }

  //   final items = cartController.cartItems;
  //   final total = items.fold<double>(0, (sum, item) {
  //     final discountedPrice =
  //         item.price * (100 - item.discountPercentage) / 100;
  //     return sum + (discountedPrice * item.quantity);
  //   });

  //   double bonus = 0.0;
  //   if (total >= 400 && total < 500) {
  //     bonus = 5.0;
  //   } else if (total >= 500 && total < 1000) {
  //     bonus = 7.0;
  //   } else if (total >= 1000 && total < 2000) {
  //     bonus = 9.0;
  //   } else if (total >= 2000) {
  //     bonus = 11.0;
  //   }

  //   if (bonus > 0) {
  //     final refererId = response.first['id'];
  //     final refererData = response.first;
  //     final dynamic balance = refererData['referBalance'];
  //     double currentBalance = 0.0;
  //     if (balance is String) {
  //       currentBalance = double.tryParse(balance) ?? 0.0;
  //     } else if (balance is num) {
  //       currentBalance = balance.toDouble();
  //     }

  //     await Supabase.instance.client.from('users').update({
  //       'referBalance': currentBalance + bonus,
  //     }).eq('id', refererId);

  //     _isReferCodeValid.value = true;
  //     _currentRefererId.value = refererId;
  //     _currentBonusGivenToReferrer.value = bonus;

  //     Get.snackbar('সফল', 'রেফারেল কোড প্রয়োগ করা হয়েছে',
  //         snackPosition: SnackPosition.BOTTOM);
  //   } else {
  //     _isReferCodeValid.value = false;
  //     Get.snackbar('ত্রুটি', 'এই অর্ডারের জন্য রেফারেল বোনাস প্রয়োজ্য নয়',
  //         snackPosition: SnackPosition.BOTTOM);
  //   }
  // }

  Future<void> _updateDeliveryFee() async {
    // Just trigger a rebuild
    setState(() {});
  }

  Future<double> _getDeliveryFee(String? division, String? district,
      String? upazila, double totalWeight) async {
    if (_isUddokta.value) {
      return 0.0; // উদ্যোক্তাদের জন্য ডেলিভারি ফি প্রযোজ্য নয়
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return 0.0;
    }

    if (division == null || district == null) {
      return 30.0;
    }

    try {
      dynamic response;
      if (upazila != null && upazila.isNotEmpty) {
        response = await Supabase.instance.client
            .from('delivery_fees')
            .select()
            .eq('division', division)
            .eq('district', district)
            .eq('upazila', upazila)
            .maybeSingle();
        if (response != null) {
          return _calculateFeeFromRule(response, totalWeight);
        }
      }

      response = await Supabase.instance.client
          .from('delivery_fees')
          .select()
          .eq('division', division)
          .eq('district', 'is.null')
          .eq('upazila', 'is.null')
          .maybeSingle();
      if (response != null) {
        return _calculateFeeFromRule(response, totalWeight);
      }

      return 30.0;
    } catch (e) {
      print('Error getting delivery fee: $e');
      return 30.0;
    }
  }

  double _calculateFeeFromRule(Map<String, dynamic> rule, double totalWeight) {
    final baseWeight = (rule['baseWeightKg'] ?? 1.0).toDouble();
    final baseFee = (rule['baseFee'] ?? 30.0).toDouble();
    final feePerExtraKg = (rule['feePerExtraKg'] ?? 10.0).toDouble();

    if (totalWeight <= baseWeight) {
      return baseFee;
    } else {
      final extraWeight = totalWeight - baseWeight;
      return baseFee + (extraWeight.ceil() * feePerExtraKg);
    }
  }

  double _calculateDiscountedTotal(double total) {
    // if (_isUddokta.value) {
    //   return 0.0; // উদ্যোক্তাদের জন্য ডিসকাউন্ট প্রযোজ্য নয়
    // }

    // if (_useReferBalance.value && _userReferBalance.value > 0) {
    //   return total > _userReferBalance.value
    //       ? total - _userReferBalance.value
    //       : 0;
    // }
    return total;
  }

  // Future<void> _updateUserReferBalance(double usedAmount) async {
  //   if (_isUddokta.value || usedAmount <= 0) {
  //     return; // উদ্যোক্তাদের জন্য রেফার ব্যালেন্স আপডেট প্রযোজ্য নয়
  //   }

  //   final user = Supabase.instance.client.auth.currentUser;
  //   if (user != null) {
  //     final userDoc = await Supabase.instance.client
  //         .from('users')
  //         .select('referBalance')
  //         .eq('id', user.id)
  //         .maybeSingle();
  //     if (userDoc == null) return;
  //     final data = userDoc;
  //     final dynamic balance = data['referBalance'];
  //     double currentBalance = 0.0;
  //     if (balance is String) {
  //       currentBalance = double.tryParse(balance) ?? 0.0;
  //     } else if (balance is num) {
  //       currentBalance = balance.toDouble();
  //     }
  //     final newBalance = currentBalance - usedAmount;

  //     await Supabase.instance.client.from('users').update({
  //       'referBalance': newBalance > 0 ? newBalance : 0,
  //     }).eq('id', user.id);
  //   }
  // }

  Future<void> _placeOrder(
      {required String orderId, required String paymentStatus}) async {
    if (_isUddokta.value) {
      Get.snackbar('ত্রুটি', 'উদ্যোক্তা হিসেবে অর্ডার করা যাবে না',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    // This check is now handled by the caller.
    if (user == null) {
      print("Error: _placeOrder called without a logged-in user.");
      return;
    }

    // ✅ লোকেশন সার্ভিস থেকে বর্তমান লোকেশন পাওয়া
    String? userLocationData = await LocationService.getCurrentLocation();

    if (userLocationData == null) {
      Get.snackbar('ত্রুটি',
          'আপনার বর্তমান GPS লোকেশন পাওয়া যায়নি। অনুগ্রহ করে লোকেশন সার্ভিস চালু করুন এবং পারমিশন দিন।',
          snackPosition: SnackPosition.BOTTOM);
      return; // Stop the order placement if location is not available
    }

    String userName = '';
    String userPhone = '';
    Map<String, dynamic> userLocation = {};
    String specialMessage = _specialMessageController.text.trim();

    if (useNewAddress) {
      if (!_formKey.currentState!.validate()) {
        Get.snackbar('ত্রুটি', 'নতুন ঠিকানা পূরণ করুন।',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      userName = _nameController.text.trim();
      userPhone = _phoneController.text.trim();
      userLocation = {
        'division': _selectedDivision.value,
        'district': _selectedDistrict.value,
        'upazila': _selectedUpazila.value,
        'union': _selectedUnion.value,
        'village': _villageController.text.trim(),
        'ward': _wardController.text.trim(),
        'house': _houseController.text.trim(),
        'road': _roadController.text.trim(),
      };
    } else if (userData.value.isNotEmpty) {
      userName = userData.value['name'] ?? '';
      userPhone = userData.value['phone'] ?? '';
      userLocation = {
        'division': userData.value['division'] ?? '',
        'district': userData.value['district'] ?? '',
        'upazila': userData.value['upazila'] ?? '',
        'union': userData.value['union'] ?? '',
        'village': userData.value['village'] ?? '',
        'house': userData.value['house'] ?? '',
        'ward': userData.value['ward'] ?? '',
        'road': userData.value['road'] ?? '',
      };
    }

    final division = userLocation['division'];
    final district = userLocation['district'];
    final upazila = userLocation['upazila'];
    final totalWeight = cartController.cartItems.fold<double>(
        0, (sum, item) => sum + ((item.weightInKg ?? 0.0) * item.quantity));
    final calculatedDeliveryFee =
        await _getDeliveryFee(division, district, upazila, totalWeight);

    final items = cartController.cartItems;
    final total = items.fold<double>(0, (sum, item) {
      final discountedPrice =
          item.price * (100 - item.discountPercentage) / 100;
      return sum + (discountedPrice * item.quantity);
    });
    final grandTotal = total + calculatedDeliveryFee;
    final discountedTotal = _calculateDiscountedTotal(grandTotal);
    final usedReferBalance = grandTotal - discountedTotal;

    debugPrint(
        'CartScreen: _placeOrder called for orderId: $orderId, paymentStatus: $paymentStatus');

    await cartController.placeOrder(
      userName: userName,
      userPhone: userPhone,
      userLocation: userLocation,
      userGpsLocation: userLocationData, // ✅ GPS লোকেশন পাস করা হল
      specialMessage: specialMessage,
      paymentMethod: selectedPaymentMethod,
      trxId: '',
      userPaymentNumber: '',
      cartItems: cartController.cartItems,
      // referCode: _referCodeController.text.trim(),
      // useReferBalance: _useReferBalance.value,
      // referBalanceUsed: usedReferBalance,
      // refererId: _currentRefererId.value,
      // bonusGivenToReferrer: _currentBonusGivenToReferrer.value,
    );

    _specialMessageController.clear();
    _referCodeController.clear();
    trxIdController.clear();
    userPaymentNumberController.clear();

    // Show success message
    Get.snackbar(
      'অর্ডার সফল',
      'আপনার অর্ডারটি সফলভাবে গ্রহণ করা হয়েছে। ইনশাআল্লাহ ২৪–৭২ ঘণ্টার মধ্যে, সর্বাধিক ৭ দিনের মধ্যে আপনার পণ্য পৌঁছে যাবে।',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
    );

    debugPrint('CartScreen: Attempting to navigate to MyOrdersScreen.');
    try {
      Get.off(() => MyOrdersScreen());
      debugPrint('CartScreen: Navigation to MyOrdersScreen successful.');
    } catch (e) {
      debugPrint('CartScreen: Error during navigation to MyOrdersScreen: $e');
      Get.snackbar('Navigation Error', 'Could not navigate to My Orders: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> _startPaymentFlow() async {
    if (_isUddokta.value) {
      Get.snackbar('ত্রুটি', 'উদ্যোক্তা হিসেবে অর্ডার করা যাবে না',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.snackbar('দুঃখিত', 'অনলাইন পেমেন্ট শীঘ্রই আসছে।');
  }

  // =================================================================
  // === সম্পূর্ণ পরিবর্তিত ফাংশন: _handleOrderPlacement ===
  // =================================================================
  Future<void> _handleOrderPlacement() async {
    debugPrint('CartScreen: _handleOrderPlacement called');

    if (_isUddokta.value) {
      Get.snackbar('ত্রুটি', 'উদ্যোক্তা হিসেবে অর্ডার করা যাবে না',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('CartScreen: User is logged in: ${user != null}');

    if (user == null) {
      // User is not logged in, navigate to registration.
      debugPrint(
          'CartScreen: User not logged in. Navigating to registration screen.');

      // Get.off ব্যবহার করা হচ্ছে যাতে ইউজার রেজিস্ট্রেশন শেষ না করে কার্ট স্ক্রিনে ফিরতে না পারে
      Get.off(
        () => dokane.RegistrationScreen(
          fromCart: true,
          onRegistrationComplete: (registrationData) async {
            debugPrint(
                'CartScreen: Registration complete with data: $registrationData');

            // রেজিস্ট্রেশনের পর নতুন ডাটা দিয়ে স্ক্রিন আপডেট করুন
            userData.value = registrationData;
            _nameController.text = registrationData['name'] ?? '';
            _phoneController.text = registrationData['phone'] ?? '';
            _selectedDivision.value = registrationData['division'] ?? '';
            _selectedDistrict.value = registrationData['district'] ?? '';
            _selectedUpazila.value = registrationData['upazila'] ?? '';
            _selectedUnion.value = registrationData['union'] ?? '';
            _villageController.text = registrationData['village'] ?? '';
            _wardController.text = registrationData['ward'] ?? '';
            _houseController.text = registrationData['house'] ?? '';
            _roadController.text = registrationData['road'] ?? '';
            _updateDeliveryFee();
            // _loadUserReferBalance();

            // এখন ইউজার রেজিস্টার্ড, তাই সরাসরি অর্ডার প্লেস করার চেষ্টা করুন
            debugPrint(
                'CartScreen: Proceeding with order placement after registration.');
            if (selectedPaymentMethod == 'Cash on Delivery') {
              String orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
              await _placeOrder(orderId: orderId, paymentStatus: 'pending');
            } else {
              await _startPaymentFlow();
            }
          },
        ),
      );
    } else {
      // User is logged in, proceed with placing the order.
      debugPrint(
          'CartScreen: User is logged in, proceeding with order placement.');
      if (selectedPaymentMethod == 'Cash on Delivery') {
        String orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
        await _placeOrder(orderId: orderId, paymentStatus: 'pending');
      } else {
        await _startPaymentFlow();
      }
    }
  }

  // নতুন মেথড যোগ করা হল
  Future<void> _switchToCustomerAccount() async {
    await Supabase.instance.client.auth.signOut();
    Get.to(() => dokane.RegistrationScreen(fromCart: true));
  }

  Widget _buildCartItemsList() {
    // কার্ট আইটেম খালি কিনা চেক করা হল
    if (cartController.cartItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'আপনার কার্ট খালি',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'অর্ডার করার জন্য পণ্য যোগ করুন',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartController.cartItems.length,
      itemBuilder: (context, index) {
        final item = cartController.cartItems[index];
        final discountedPrice =
            item.price * (100 - item.discountPercentage) / 100;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Image.network(item.imageUrl,
                    width: 50, height: 50, fit: BoxFit.cover),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('মূল্য: ৳${discountedPrice.toStringAsFixed(2)}'),
                      Text(
                          'ছাড়: ৳${(item.price - discountedPrice).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        cartController.decreaseQuantity(
                          item.id,
                          color: item.color,
                          size: item.size,
                        );
                      },
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        cartController.increaseQuantity(
                          item.id,
                          color: item.color,
                          size: item.size,
                        );
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    cartController.removeFromCart(
                      item.id,
                      color: item.color,
                      size: item.size,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressSection() {
    // উদ্যোক্তা কিনা চেক করা হল
    if (_isUddokta.value) {
      return Container(); // উদ্যোক্তাদের জন্য ঠিকানা সেকশন দেখাবে না
    }

    String fullAddress = '';
    if (userData.value.isNotEmpty) {
      final addressParts = [
        userData.value['house'],
        userData.value['ward'],
        userData.value['road'],
        userData.value['village'],
        userData.value['upazila'],
        userData.value['union'],
        userData.value['district'],
        userData.value['division']
      ];
      fullAddress =
          addressParts.where((s) => s != null && s.isNotEmpty).join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ডেলিভারি ঠিকানা',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (userData.value.isNotEmpty && !useNewAddress)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('নাম: ${userData.value['name'] ?? ''}'),
                  Text('মোবাইল: ${userData.value['phone'] ?? ''}'),
                  Text('ঠিকানা: $fullAddress'),
                ],
              ),
            ),
          ),
        CheckboxListTile(
          title: const Text('নতুন ঠিকানা ব্যবহার করুন'),
          value: useNewAddress,
          onChanged: (value) {
            setState(() {
              useNewAddress = value!;
            });
            _updateDeliveryFee();
          },
        ),
        if (useNewAddress)
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'নাম'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'নাম লিখুন' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'ফোন নম্বর'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ফোন নম্বর লিখুন';
                    }
                    if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                      return 'সঠিক ফোন নম্বর দিন';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDivision.value.isNotEmpty
                      ? _selectedDivision.value
                      : null,
                  decoration: const InputDecoration(labelText: 'বিভাগ'),
                  items: locationData.keys
                      .map((division) => DropdownMenuItem(
                          value: division, child: Text(division)))
                      .toList(),
                  onChanged: (value) {
                    _selectedDivision.value = value ?? '';
                    _selectedDistrict.value = '';
                    _selectedUpazila.value = '';
                    _updateDeliveryFee();
                  },
                  validator: (value) =>
                      value == null ? 'বিভাগ নির্বাচন করুন' : null,
                ),
                if (_selectedDivision.value.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDistrict.value.isNotEmpty
                        ? _selectedDistrict.value
                        : null,
                    decoration: const InputDecoration(labelText: 'জেলা'),
                    items: locationData[_selectedDivision.value]!
                        .keys
                        .map((district) => DropdownMenuItem(
                            value: district, child: Text(district)))
                        .toList(),
                    onChanged: (value) {
                      _selectedDistrict.value = value ?? '';
                      _selectedUpazila.value = '';
                      _updateDeliveryFee();
                    },
                    validator: (value) =>
                        value == null ? 'জেলা নির্বাচন করুন' : null,
                  ),
                if (_selectedDistrict.value.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUpazila.value.isNotEmpty
                        ? _selectedUpazila.value
                        : null,
                    decoration: const InputDecoration(labelText: 'উপজেলা'),
                    items: locationData[_selectedDivision.value]![
                            _selectedDistrict.value]!
                        .keys
                        .map((upazila) => DropdownMenuItem(
                            value: upazila, child: Text(upazila)))
                        .toList(),
                    onChanged: (value) {
                      _selectedUpazila.value = value ?? '';
                      _selectedUnion.value = '';
                      _updateDeliveryFee();
                    },
                    validator: (value) =>
                        value == null ? 'উপজেলা নির্বাচন করুন' : null,
                  ),
                if (_selectedUpazila.value.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnion.value.isNotEmpty
                        ? _selectedUnion.value
                        : null,
                    decoration: const InputDecoration(labelText: 'ইউনিয়ন'),
                    items: locationData[_selectedDivision.value]![
                            _selectedDistrict.value]![_selectedUpazila.value]!
                        .map((union) =>
                            DropdownMenuItem(value: union, child: Text(union)))
                        .toList(),
                    onChanged: (value) {
                      _selectedUnion.value = value ?? '';
                      _updateDeliveryFee();
                    },
                    validator: (value) =>
                        value == null ? 'ইউনিয়ন নির্বাচন করুন' : null,
                  ),
                TextFormField(
                  controller: _villageController,
                  decoration: const InputDecoration(labelText: 'গ্রাম'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'গ্রাম লিখুন' : null,
                ),
                TextFormField(
                  controller: _wardController,
                  decoration: const InputDecoration(labelText: 'ওয়ার্ড নং'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'ওয়ার্ড নং লিখুন'
                      : null,
                ),
                TextFormField(
                  controller: _houseController,
                  decoration: const InputDecoration(labelText: 'বাড়ি নং'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'বাড়ি নং লিখুন'
                      : null,
                ),
                TextFormField(
                  controller: _roadController,
                  decoration: const InputDecoration(labelText: 'রোড নং'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'রোড নং লিখুন' : null,
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'বিশেষ বার্তা (ঐচ্ছিক)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _specialMessageController,
                decoration: const InputDecoration(
                  hintText: 'ডেলিভারি সম্পর্কে বিশেষ নির্দেশনা লিখুন...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              const Text(
                'যেমন: ডেলিভারি সময় ফোন করুন, গেটের কোড: 1234, পাশের দোকানের নাম, ইত্যাদি',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialMessageAndReferSection() {
    // উদ্যোক্তা কিনা চেক করা হল
    // if (_isUddokta.value) {
    //   return Container(); // উদ্যোক্তাদের জন্য রেফার সেকশন দেখাবে না
    // }

    // return Container(
    //   margin: const EdgeInsets.only(top: 16.0),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       if (!_useReferBalance.value) ...[
    //         const Text(
    //           'রেফারেল কোড',
    //           style: TextStyle(
    //             fontSize: 16,
    //             fontWeight: FontWeight.bold,
    //           ),
    //         ),
    //         const SizedBox(height: 8),
    //         Obx(() => TextFormField(
    //               controller: _referCodeController,
    //               decoration: InputDecoration(
    //                 hintText: 'রেফারেল কোড লিখুন...',
    //                 border: OutlineInputBorder(
    //                   borderSide: BorderSide(
    //                     color:
    //                         _isReferCodeValid.value ? Colors.grey : Colors.red,
    //                   ),
    //                 ),
    //                 errorText:
    //                     _isReferCodeValid.value ? null : 'অবৈধ রেফারেল কোড',
    //               ),
    //               onChanged: (value) {
    //                 _isReferCodeValid.value = true;
    //               },
    //             )),
    //         const SizedBox(height: 16),
    //       ],
    //       Row(
    //         children: [
    //           Checkbox(
    //             value: _useReferBalance.value,
    //             onChanged: (value) {
    //               _useReferBalance.value = value ?? false;
    //             },
    //           ),
    //           const Text('রেফারেল ব্যালেন্স ব্যবহার করুন'),
    //         ],
    //       ),
    //       if (_useReferBalance.value)
    //         Text(
    //           'আপনার রেফারেল ব্যালেন্স: ৳${_userReferBalance.value.toStringAsFixed(2)}',
    //           style: const TextStyle(fontWeight: FontWeight.bold),
    //         ),
    //     ],
    //   ),
    // );
    return Container();
  }

  Widget _buildPaymentSection() {
    // উদ্যোক্তা কিনা চেক করা হল
    if (_isUddokta.value) {
      // উদ্যোক্তাদের জন্য আলাদা UI
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'আপনি উদ্যোক্তা হিসেবে লগইন করেছেন',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'অর্ডার করার জন্য ক্রেতা হিসেবে লগইন করুন',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _switchToCustomerAccount,
              icon: Icon(Icons.person_add),
              label: Text('ক্রেতা হিসেবে রেজিস্ট্রেশন করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // কার্ট আইটেম খালি কিনা চেক করা হল
    if (cartController.cartItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'আপনার কার্ট খালি',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'অর্ডার করার জন্য পণ্য যোগ করুন',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final items = cartController.cartItems;
    final total = items.fold<double>(0, (sum, item) {
      final discountedPrice =
          item.price * (100 - item.discountPercentage) / 100;
      return sum + (discountedPrice * item.quantity);
    });

    String? division;
    String? district;
    String? upazila;
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      if (useNewAddress) {
        division =
            _selectedDivision.value.isNotEmpty ? _selectedDivision.value : null;
        district =
            _selectedDistrict.value.isNotEmpty ? _selectedDistrict.value : null;
        upazila =
            _selectedUpazila.value.isNotEmpty ? _selectedUpazila.value : null;
      } else if (userData.value.isNotEmpty) {
        division = userData.value['division'];
        district = userData.value['district'];
        upazila = userData.value['upazila'];
      }
    }
    final totalWeight = cartController.cartItems.fold<double>(
        0, (sum, item) => sum + ((item.weightInKg ?? 0.0) * item.quantity));

    // ডেলিভারি ফি ক্যালকুলেশন ফিউচার বিল্ডারের জন্য একটি স্টেটফুল ওয়াইজেট
    return FutureBuilder<double>(
      future: _getDeliveryFee(division, district, upazila, totalWeight),
      builder: (context, snapshot) {
        final deliveryFee = snapshot.data ?? 0.0;
        final grandTotal = total + deliveryFee;
        final discountedTotal = _calculateDiscountedTotal(grandTotal);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('পেমেন্ট বিবরণ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('মোট মূল্য:'),
                        Text('৳${total.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ডেলিভারি চার্জ:'),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const CircularProgressIndicator()
                        else
                          Text('৳${deliveryFee.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (_useReferBalance.value && _userReferBalance.value > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('রেফারেল ব্যালেন্স ব্যবহার:'),
                          Text(
                              '৳${grandTotal - discountedTotal > _userReferBalance.value ? _userReferBalance.value.toStringAsFixed(2) : (grandTotal - discountedTotal).toStringAsFixed(2)}'),
                        ],
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('সর্বমোট:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('৳${discountedTotal.toStringAsFixed(2)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('পেমেন্ট পদ্ধতি',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: const Text('ক্যাশ অন ডেলিভারি'),
              value: 'Cash on Delivery',
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _handleOrderPlacement,
                child: const Text('অর্ডার করুন'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // টপ লেভেল Obx ব্যবহার করা হল
    return Obx(() {
      // লোডিং স্টেট চেক করা হল
      if (_isLoading.value) {
        return BackgroundContainer(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 10,
              title: Row(
                children: [
                  const Text('আমার অর্ডারসমূহ'),
                ],
              ),
            ),
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      // কার্ট আইটেম ভার্শন অ্যাক্সেস করা হল (এটি নিশ্চিত করে যে কার্ট আইটেম পরিবর্তন হলে রিবিল্ড হবে)
      final cartItemsLength = cartController.cartItems.length;

      return BackgroundContainer(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 10,
            title: Row(
              children: [
                const Text('অর্ডার করুন'),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCartItemsList(),
                const SizedBox(height: 20),
                _buildAddressSection(),
                _buildSpecialMessageAndReferSection(),
                _buildPaymentSection(),
              ],
            ),
          ),
        ),
      );
    });
  }
}
