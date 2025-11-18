class LabelService {
  Map<String, dynamic>? _labels;

  Map<String, dynamic>? get labels => _labels;

  void loadLabels() {
    _labels = {
      'orderManagement': 'অর্ডার ম্যানেজমেন্ট',
      'refreshOrders': 'Refresh Orders',
      'clearFilters': 'Clear Filters',
      'totalOrders': 'মোট অর্ডার',
      'filteredOrders': 'ফিল্টার করা অর্ডার',
      'todayOrders': 'আজকের অর্ডার',
      'loading': 'লোড হচ্ছে...',
      'searchHint': 'নাম বা অর্ডার আইডি দিয়ে সার্চ করুন',
      'status': 'স্ট্যাটাস',
      'paymentStatus': 'পেমেন্ট স্ট্যাটাস',
      'date': 'তারিখ',
      'todaysOrders': 'আজকের অর্ডার',
      'allOrders': 'সকল অর্ডার',
      'noTodaysOrders': 'আজকের কোনো অর্ডার পাওয়া যায়নি',
      'noOrdersFound': 'কোনো অর্ডার পাওয়া যায়নি',
      'orderTime': 'অর্ডার সময়',
      'clearDate': 'Clear Date',
      'all': 'সব',
      'pending': 'পেন্ডিং',
      'shipped': 'শিপড',
      'delivered': 'ডেলিভারড',
      'cancelled': 'ক্যানসেলড',
      'orderReport': 'অর্ডার রিপোর্ট',
      'generatePdfReport': 'পিডিএফ রিপোর্ট তৈরি করুন',
      'generateExcelReport': 'এক্সেল রিপোর্ট তৈরি করুন',
      'orderId': 'অর্ডার আইডি',
      'customerName': 'গ্রাহকের নাম',
      'phone': 'ফোন',
      'location': 'লোকেশন',
      'items': 'আইটেম',
      'total': 'মোট',
      'deliveryCharge': 'ডেলিভারি চার্জ',
      'grandTotal': 'সর্বমোট',
      'paymentMethod': 'পেমেন্ট মেথড',
      'trxId': 'ট্রানজেকশন আইডি',
      'userPaymentNumber': 'পেমেন্ট নাম্বার',
      'orderDate': 'অর্ডার তারিখ',
      'specialMessage': 'বিশেষ বার্তা',
      'unknown': 'অজানা',
      'downloadPdf': 'PDF ডাউনলোড',
      'downloadExcel': 'Excel ডাউনলোড',
      'orderDetails': 'অর্ডার বিবরণ',
      'itemName': 'আইটেমের নাম',
      'quantity': 'পরিমাণ',
      'price': 'মূল্য',
    };
  }

  String? getLabel(String key) {
    return _labels?[key];
  }
}