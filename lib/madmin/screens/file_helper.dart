import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static Future<File?> writeCsvToFile(String csvData, String fileName) async {
    try {
      if (kIsWeb) {
        print("Writing file is not supported on Web.");
        return null;
      }
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      return await file.writeAsString(csvData);
    } catch (e) {
      print("File write error: $e");
      return null;
    }
  }
}
