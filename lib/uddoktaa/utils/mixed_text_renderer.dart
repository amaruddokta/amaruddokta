import 'package:pdf/widgets.dart' as pw;
import 'package:amar_uddokta/uddoktaa/utils/font_helper.dart';
import 'package:amar_uddokta/uddoktaa/utils/unicode_to_bijoy.dart';

class MixedTextRenderer {
  // একটি অক্ষর বাংলা কিনা তা চেক করার ফাংশন
  static bool _isBengaliChar(String char) {
    final codeUnit = char.codeUnitAt(0);
    // The Taka sign (৳) is U+09F3. We exclude it from the Bengali range
    // to let the English font handle it, as it's often missing from Bengali fonts.
    if (codeUnit == 0x09F3) {
      return false;
    }
    return (codeUnit >= 0x0980 && codeUnit <= 0x09FF);
  }

  // টেক্সটকে বাংলা এবং ইংরেজি সেগমেন্টে ভাগ করা
  static List<Map<String, dynamic>> _splitText(String text) {
    final segments = <Map<String, dynamic>>[];
    if (text.isEmpty) return segments;

    String currentSegment = '';
    bool? currentIsBengali;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isBengali = _isBengaliChar(char);

      if (currentSegment.isEmpty) {
        currentSegment = char;
        currentIsBengali = isBengali;
      } else if (currentIsBengali == isBengali) {
        currentSegment += char;
      } else {
        segments.add({
          'text': currentSegment,
          'isBengali': currentIsBengali!,
        });
        currentSegment = char;
        currentIsBengali = isBengali;
      }
    }

    if (currentSegment.isNotEmpty) {
      segments.add({
        'text': currentSegment,
        'isBengali': currentIsBengali!,
      });
    }

    return segments;
  }

  // মিক্সড টেক্সট রেন্ডার করার ফাংশন
  static pw.Widget render(
    String text, {
    pw.TextStyle? style,
    pw.TextAlign? textAlign,
    required pw.Font bengaliFont,
    required pw.Font englishFont,
  }) {
    final segments = _splitText(text);

    return pw.RichText(
      text: pw.TextSpan(
        children: segments.map((segment) {
          final isBengali = segment['isBengali'] as bool;
          final segmentText = segment['text'] as String;

          // বাংলা টেক্সট হলে বিজয়ে কনভার্ট করুন
          final displayText = isBengali
              ? UnicodeToBijoyConverter.convert(segmentText)
              : segmentText;

          return pw.TextSpan(
            text: displayText,
            style: (style ?? pw.TextStyle()).copyWith(
              font: isBengali ? bengaliFont : englishFont,
            ),
          );
        }).toList(),
      ),
      textAlign: textAlign,
    );
  }
}
