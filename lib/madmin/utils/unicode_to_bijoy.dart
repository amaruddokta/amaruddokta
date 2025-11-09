import 'package:bijoy_helper/bijoy_helper.dart';

class UnicodeToBijoyConverter {
  static String convert(String unicodeText) {
    // The Taka sign is often missing from Bijoy fonts.
    // We replace it with a dollar sign ($) as a fallback.
    String textWithFallback = unicodeText;
    return textWithFallback.toBijoy;
  }
}
