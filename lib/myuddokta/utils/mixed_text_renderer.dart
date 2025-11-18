// ফাইল: lib/madmin/utils/mixed_text_renderer.dart

import 'package:pdf/widgets.dart' as pw;

class MixedTextRenderer {
  static pw.Widget render(
    String text, {
    pw.TextStyle? style,
    required pw.Font bengaliFont,
    required pw.Font englishFont,
  }) {
    // বাংলা অক্ষর চেনার জন্য একটি রেগুলার এক্সপ্রেশন
    final bengaliRegex = RegExp(r'[\u0980-\u09FF]');

    final spans = <pw.TextSpan>[];
    final currentRun = StringBuffer();
    pw.Font? currentFont;

    // স্ট্রিং-এর প্রতিটি অক্ষর চেক করে ফন্ট পরিবর্তন করা হচ্ছে
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isBengali = bengaliRegex.hasMatch(char);
      final charFont = isBengali ? bengaliFont : englishFont;

      if (currentFont == null) {
        currentFont = charFont;
        currentRun.write(char);
      } else if (currentFont == charFont) {
        currentRun.write(char);
      } else {
        spans.add(pw.TextSpan(
          text: currentRun.toString(),
          style: (style ?? pw.TextStyle()).copyWith(font: currentFont),
        ));
        currentRun.clear();
        currentFont = charFont;
        currentRun.write(char);
      }
    }

    // শেষের অংশটুকু যোগ করা হচ্ছে
    if (currentRun.isNotEmpty) {
      spans.add(pw.TextSpan(
        text: currentRun.toString(),
        style: (style ?? pw.TextStyle()).copyWith(font: currentFont),
      ));
    }

    return pw.RichText(text: pw.TextSpan(children: spans));
  }
}
