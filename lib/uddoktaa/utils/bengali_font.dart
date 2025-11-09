import 'package:pdf/widgets.dart' as pw;

class BengaliFont {
  static const String bengaliRegular = '''
    অ আ ই ঈ উ ঊ ঋ এ ঐ ও ঔ ক খ গ ঘ ঙ চ ছ জ ঝ ঞ ট ঠ ড ঢ ণ ত থ দ ধ ন প ফ ব ভ ম য র ল শ ষ স হ ড় ঢ় য় ৎ ং ঃ ঁ ০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯ ৎ ড় ঢ় য়
  ''';

  static const String bengaliBold = '''
    অ আ ই ঈ উ ঊ ঋ এ ঐ ও ঔ ক খ গ ঘ ঙ চ ছ জ ঝ ঞ ট ঠ ড ঢ ণ ত থ দ ধ ন প ফ ব ভ ম য র ল শ ষ স হ ড় ঢ় য় ৎ ং ঃ ঁ ০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯ ৎ ড় ঢ় য়
  ''';

  static pw.Font get regular => pw.Font.courier();
  static pw.Font get bold => pw.Font.courierBold();
}
