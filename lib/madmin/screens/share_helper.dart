// ignore_for_file: unused_impor
import 'package:share_plus/share_plus.dart' as SharePlus;

class ShareHelper {
  static Future<void> shareFile(String filePath) async {
    try {
      await SharePlus.Share.shareXFiles([SharePlus.XFile(filePath)],
          text: 'Exported CSV File');
    } catch (e) {
      print("Share error: $e");
    }
  }
}
