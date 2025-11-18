import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

class FontHelper {
  static const String _fontPath = 'assets/fonts/SutonnyMJ Regular.ttf';
  static pw.Font? _bengaliRegular;
  static pw.Font? _bengaliBold;

  static Future<pw.Font> getBengaliRegular() async {
    if (_bengaliRegular == null) {
      final fontData = await rootBundle.load(_fontPath);
      _bengaliRegular = pw.Font.ttf(fontData);
    }
    return _bengaliRegular!;
  }

  static Future<pw.Font> getBengaliBold() async {
    if (_bengaliBold == null) {
      final fontData = await rootBundle.load(_fontPath);
      _bengaliBold = pw.Font.ttf(fontData);
    }
    return _bengaliBold!;
  }

  static pw.Font getEnglishRegular() {
    return pw.Font.helvetica();
  }

  static pw.Font getEnglishBold() {
    return pw.Font.helveticaBold();
  }
}
