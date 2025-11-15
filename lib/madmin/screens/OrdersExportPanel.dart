import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:universal_html/html.dart' as html;

class OrdersExportPanel extends StatefulWidget {
  const OrdersExportPanel({super.key});

  @override
  State<OrdersExportPanel> createState() => _OrdersExportPanelState();
}

class _OrdersExportPanelState extends State<OrdersExportPanel> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final response = await Supabase.instance.client
        .from('orders')
        .select()
        .order('orderTime', ascending: false);

    orders = List<Map<String, dynamic>>.from(response);
    setState(() => isLoading = false);
  }

  Future<void> exportOrdersToPdf(List<Map<String, dynamic>> orders) async {
    final pdf = PdfDocument();
    final page = pdf.pages.add();
    final grid = PdfGrid();

    grid.columns.add(count: 5);
    grid.headers.add(1);
    final header = grid.headers[0];
    header.cells[0].value = 'Order ID';
    header.cells[1].value = 'User Name';
    header.cells[2].value = 'Total';
    header.cells[3].value = 'Status';
    header.cells[4].value = 'Payment';

    for (final order in orders) {
      final row = grid.rows.add();
      row.cells[0].value = order['order_id'] ?? '';
      row.cells[1].value = order['user_name'] ?? '';
      row.cells[2].value = order['grand_total'].toString();
      row.cells[3].value = order['status'] ?? '';
      row.cells[4].value = order['payment_status'] ?? '';
    }

    grid.draw(page: page, bounds: const Rect.fromLTWH(0, 0, 500, 800));
    final bytes = await pdf.save();
    pdf.dispose();

    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "orders.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> exportOrdersToExcel(List<Map<String, dynamic>> orders) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Orders';

    sheet.getRangeByName('A1').setText('Order ID');
    sheet.getRangeByName('B1').setText('User Name');
    sheet.getRangeByName('C1').setText('Total');
    sheet.getRangeByName('D1').setText('Status');
    sheet.getRangeByName('E1').setText('Payment');

    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      sheet.getRangeByIndex(i + 2, 1).setText(order['order_id'] ?? '');
      sheet.getRangeByIndex(i + 2, 2).setText(order['user_name'] ?? '');
      sheet
          .getRangeByIndex(i + 2, 3)
          .setNumber(order['grand_total']?.toDouble() ?? 0);
      sheet.getRangeByIndex(i + 2, 4).setText(order['status'] ?? '');
      sheet.getRangeByIndex(i + 2, 5).setText(order['payment_status'] ?? '');
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final blob = html.Blob([bytes],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "orders.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('অর্ডার এক্সপোর্ট')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => exportOrdersToPdf(orders),
                      child: const Text('Export PDF'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => exportOrdersToExcel(orders),
                      child: const Text('Export Excel'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return ListTile(
                        title: Text('Order: ${order['order_id']}'),
                        subtitle: Text(
                            '${order['user_name']} - ৳${order['grand_total']}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(order['status'] ?? ''),
                            Text(order['payment_status'] ?? ''),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}
