import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';

Future<void> exportOrdersToExcel(List<Map<String, dynamic>> orders) async {
  final xlsio.Workbook workbook = xlsio.Workbook();
  final xlsio.Worksheet sheet = workbook.worksheets[0];

  // Headers
  final headers = ['Order ID', 'User Name', 'Total', 'Status', 'Payment Status'];
  for (int i = 0; i < headers.length; i++) {
    sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
  }

  // Data rows
  for (int i = 0; i < orders.length; i++) {
    final order = orders[i];
    sheet.getRangeByIndex(i + 2, 1).setText(order['orderId'] ?? '');
    sheet.getRangeByIndex(i + 2, 2).setText(order['userName'] ?? '');
    sheet.getRangeByIndex(i + 2, 3).setNumber(order['grandTotal']?.toDouble() ?? 0.0);
    sheet.getRangeByIndex(i + 2, 4).setText(order['status'] ?? '');
    sheet.getRangeByIndex(i + 2, 5).setText(order['paymentStatus'] ?? '');
  }

  // Save file
  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/orders_report.xlsx';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);

  await OpenFilex.open(path);
}
