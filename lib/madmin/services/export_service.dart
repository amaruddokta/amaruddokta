import 'dart:io';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// PDF Export Function
Future<void> exportOrdersToPdf(List<Map<String, dynamic>> orders) async {
  // Create a PDF document.
  final PdfDocument document = PdfDocument();

  // Add a page.
  final PdfPage page = document.pages.add();

  // Create a PDF grid.
  final PdfGrid grid = PdfGrid();

  // Define columns.
  grid.columns.add(count: 5);

  // Add header row.
  final PdfGridRow header = grid.headers.add(1)[0];
  header.cells[0].value = 'Order ID';
  header.cells[1].value = 'User Name';
  header.cells[2].value = 'Grand Total';
  header.cells[3].value = 'Status';
  header.cells[4].value = 'Payment Status';

  // Add rows.
  for (var order in orders) {
    final PdfGridRow row = grid.rows.add();
    row.cells[0].value = order['orderId']?.toString() ?? '';
    row.cells[1].value = order['userName']?.toString() ?? '';
    row.cells[2].value = order['grandTotal']?.toString() ?? '';
    row.cells[3].value = order['status']?.toString() ?? '';
    row.cells[4].value = order['paymentStatus']?.toString() ?? '';
  }

  // Draw the grid on the page.
  grid.draw(
    page: page,
    bounds: const Rect.fromLTWH(0, 0, 0, 0),
  );

  // Save the document to bytes.
  final List<int> bytes = document.saveSync();
  document.dispose();

  // Get file path.
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/orders_export.pdf';

  // Save the file.
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);

  // Open the file (optional).
  await OpenFilex.open(path);
}

/// Excel Export Function
Future<void> exportOrdersToExcel(List<Map<String, dynamic>> orders) async {
  // Create a new Excel document.
  final xlsio.Workbook workbook = xlsio.Workbook();
  final xlsio.Worksheet sheet = workbook.worksheets[0];

  // Set headers.
  sheet.getRangeByIndex(1, 1).setText('Order ID');
  sheet.getRangeByIndex(1, 2).setText('User Name');
  sheet.getRangeByIndex(1, 3).setText('Grand Total');
  sheet.getRangeByIndex(1, 4).setText('Status');
  sheet.getRangeByIndex(1, 5).setText('Payment Status');

  // Fill data rows.
  for (int i = 0; i < orders.length; i++) {
    final order = orders[i];
    final rowIndex = i + 2;

    sheet.getRangeByIndex(rowIndex, 1).setText(order['orderId']?.toString() ?? '');
    sheet.getRangeByIndex(rowIndex, 2).setText(order['userName']?.toString() ?? '');
    sheet.getRangeByIndex(rowIndex, 3).setNumber((num.tryParse(order['grandTotal'].toString()) ?? 0).toDouble());
    sheet.getRangeByIndex(rowIndex, 4).setText(order['status']?.toString() ?? '');
    sheet.getRangeByIndex(rowIndex, 5).setText(order['paymentStatus']?.toString() ?? '');
  }

  // Save the workbook to bytes.
  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  // Get file path.
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/orders_export.xlsx';

  // Save the file.
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);

  // Open the file (optional).
  await OpenFilex.open(path);
}
