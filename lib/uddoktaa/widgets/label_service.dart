import 'package:supabase_flutter/supabase_flutter.dart';

class LabelService {
  static final LabelService _instance = LabelService._internal();
  factory LabelService() => _instance;
  LabelService._internal();

  Map<String, dynamic>? _labels;

  Map<String, dynamic>? get labels => _labels;

  Future<void> loadLabels() async {
    try {
      final response = await Supabase.instance.client
          .from('appLabels')
          .select('labels')
          .eq('id', 'bn')
          .single();

      _labels = response['labels'];
    } catch (e) {
      print('Error loading labels: $e');
      _labels = _getDefaultLabels();
    }
  }

  Map<String, dynamic> _getDefaultLabels() {
    return {
      'orderId': 'অর্ডার আইডি',
      'userName': 'নাম',
      'userPhone': 'ফোন',
      'paymentMethod': 'পেমেন্ট মেথড',
      'paymentStatus': 'পেমেন্ট স্ট্যাটাস',
      'trxId': 'ট্রানজেকশন আইডি',
      'userPaymentNumber': 'পেমেন্ট নাম্বার',
      'placedAt': 'অর্ডার সময়',
      'status': 'স্ট্যাটাস',
      'cancelledAt': 'বাতিলের সময়',
      'cancelledBy': 'বাতিল করেছেন',
      'deliveryCharge': 'ডেলিভারি চার্জ',
      'grandTotal': 'মোট মূল্য',
      'total': 'সাবটোটাল',
      'specialMessage': 'বিশেষ বার্তা',
      'division': 'বিভাগ',
      'district': 'জেলা',
      'upazila': 'উপজেলা',
      'village': 'গ্রাম/এলাকা',
      'house': 'বাসা নম্বর',
      'road': 'রাস্তা',
      'ward': 'ওয়ার্ড',
      'items': 'পণ্য তালিকা',
      'name': 'পণ্যের নাম',
      'company': 'কোম্পানি',
      'quantity': 'পরিমাণ',
      'price': 'একক মূল্য',
      'unit': 'ইউনিট',
      'statusOptions': {
        'pending': 'পেন্ডিং',
        'shipped': 'শিপড',
        'delivered': 'ডেলিভারড',
        'cancelled': 'বাতিল'
      },
      'downloadOptions': 'ডাউনলোড অপশন',
      'shareOptions': 'শেয়ার অপশন',
      'downloadAsPDF': 'PDF হিসেবে ডাউনলোড',
      'shareAsPDF': 'PDF হিসেবে শেয়ার',
      'orderDetails': 'Order Details',
      'buyerInfo': 'ক্রেতার তথ্য',
      'address': 'ঠিকানা',
      'paymentInfo': 'পেমেন্ট তথ্য',
      'priceInfo': 'মূল্য তথ্য',
      'thankYou': 'ধন্যবাদ',
      'photo': 'ছবি',
      'productName': 'পণ্যের নাম',
      'description': 'বিবরণ',
      'subtotal': 'সাবটোটাল',
      'deliveryCharges': 'ডেলিভারি চার্জ',
      'totalAmount': 'মোট মূল্য',
      'user': 'ইউজার',
      'admin': 'অ্যাডমিন',
      'statusChange': 'স্ট্যাটাস পরিবর্তন',
      'paymentSuccess': 'পেমেন্ট সফল',
      'orderManagement': 'অর্ডার ম্যানেজমেন্ট',
      'refreshOrders': 'Refresh Orders',
      'clearFilters': 'Clear Filters',
      'searchHint': 'নাম বা অর্ডার আইডি দিয়ে সার্চ করুন',
      'totalOrders': 'মোট অর্ডার',
      'filteredOrders': 'ফিল্টার করা অর্ডার',
      'todayOrders': 'আজকের অর্ডার',
      'loading': 'লোড হচ্ছে...',
      'all': 'সব',
      'date': 'তারিখ',
      'todaysOrders': 'আজকের অর্ডার',
      'allOrders': 'সকল অর্ডার',
      'noOrdersFound': 'কোনো অর্ডার পাওয়া যায়নি',
      'noTodaysOrders': 'আজকের কোনো অর্ডার পাওয়া যায়নি',
      'orderTime': 'অর্ডার সময়',
      'area': 'এলাকা',
      'addressLabel': 'ঠিকানা',
      'noImage': 'ছবি নেই',
      'pdfCreating': 'পিডিএফ তৈরি হচ্ছে...',
      'downloadStarted': 'ডাউনলোড শুরু হয়েছে...',
      'savedAt': 'সংরক্ষণ করা হয়েছে',
      'downloadError': 'ডাউনলোড করতে সমস্যা হয়েছে',
      'shareError': 'শেয়ার করতে সমস্যা হয়েছে'
    };
  }

  String getLabel(String key) {
    return _labels?[key] ?? key;
  }
}
