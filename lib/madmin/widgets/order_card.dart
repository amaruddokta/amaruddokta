import 'dart:io';
import 'package:amar_uddokta/madmin/services/LabelService.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:amar_uddokta/madmin/models/order_model.dart';
import 'package:amar_uddokta/madmin/services/location_service.dart';
import 'package:amar_uddokta/madmin/utils/font_helper.dart'; // Import FontHelper
// Import UnicodeToBijoyConverter
import 'package:amar_uddokta/madmin/utils/mixed_text_renderer.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:amar_uddokta/madmin/controller/OrderController.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final Color color;
  const OrderCard({super.key, required this.order, required this.color});

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final OrderController controller = Get.find<OrderController>();
  final LabelService labelService = LabelService();

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(fontFamily: 'SutonnyMJ'), // বিজয় ফন্ট ব্যবহার
      child: Card(
        color: widget.color,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${labelService.getLabel('orderId') ?? 'অর্ডার আইডি'}: ${widget.order.orderId}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _showDownloadOptions(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _showShareOptions(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () => _printOrder(),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${labelService.getLabel('userName') ?? 'নাম'}: ${widget.order.userName}'),
              Text(
                  '${labelService.getLabel('userPhone') ?? 'ফোন'}: ${widget.order.userPhone}'),
              Text(
                  '${labelService.getLabel('paymentMethod') ?? 'পেমেন্ট'}: ${widget.order.paymentMethod} (${widget.order.paymentStatus})'),
              Text(
                  '${labelService.getLabel('trxId') ?? 'ট্রানজেকশন আইডি'}: ${widget.order.trxId}'),
              Text(
                  '${labelService.getLabel('userPaymentNumber') ?? 'ইউজার নাম্বার'}: ${widget.order.userPaymentNumber}'),
              if (widget.order.status == 'cancelled' &&
                  widget.order.cancelledBy != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${labelService.getLabel('cancelledBy') ?? 'বাতিল করেছেন'}: ${widget.order.cancelledBy == 'user' ? labelService.getLabel('user') ?? 'ইউজার' : labelService.getLabel('admin') ?? 'অ্যাডমিন'}',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    if (widget.order.cancelledAt != null)
                      Text(
                        '${labelService.getLabel('cancelledAt') ?? 'বাতিলের সময়'}: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.order.cancelledAt!)}',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
            ],
          ),
          children: [
            _buildFullOrderDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullOrderDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '${labelService.getLabel('area') ?? 'এলাকা'}: ${widget.order.location['division']}, ${widget.order.location['district']}, ${widget.order.location['upazila']}'),
          if (widget.order.location['union'] != null &&
              (widget.order.location['union'] as String).isNotEmpty &&
              (widget.order.location['union'] as String).toLowerCase() !=
                  'null')
            Text(
                '${labelService.getLabel('union') ?? 'ইউনিয়ন'}: ${widget.order.location['union']}'),
          Text(
              '${labelService.getLabel('addressLabel') ?? 'ঠিকানা'}: ${widget.order.location['village'] ?? ''}'),
          if (widget.order.location['ward'] != null &&
              (widget.order.location['ward'] as String).isNotEmpty &&
              (widget.order.location['ward'] as String).toLowerCase() != 'null')
            Text(
                '${labelService.getLabel('ward') ?? 'ওয়ার্ড'}: ${widget.order.location['ward']}'),
          if (widget.order.location['house'] != null &&
              (widget.order.location['house'] as String).isNotEmpty &&
              (widget.order.location['house'] as String).toLowerCase() !=
                  'null')
            Text(
                '${labelService.getLabel('house') ?? 'বাসা'}: ${widget.order.location['house']}'),
          if (widget.order.location['road'] != null &&
              (widget.order.location['road'] as String).isNotEmpty &&
              (widget.order.location['road'] as String).toLowerCase() != 'null')
            Text(
                '${labelService.getLabel('road') ?? 'রাস্তা'}: ${widget.order.location['road']}'),
          if (widget.order.userGpsLocation != null &&
              Uri.tryParse(widget.order.userGpsLocation!)?.hasAbsolutePath ==
                  true)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
              child: InkWell(
                onTap: () =>
                    LocationService.launchMapUrl(widget.order.userGpsLocation!),
                child: Text(
                  'GPS Location: ${widget.order.userGpsLocation}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          Text(
              '${labelService.getLabel('placedAt') ?? 'অর্ডার সময়'}: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.order.placedAt)}'),

          // Special Message Section
          if (widget.order.specialMessage != null &&
              widget.order.specialMessage!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, color: Colors.yellow[800], size: 16),
                      SizedBox(width: 5),
                      Text(
                        '${labelService.getLabel('specialMessage') ?? 'বিশেষ বার্তা'}:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.order.specialMessage!,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                  '${labelService.getLabel('statusChange') ?? 'স্ট্যাটাস পরিবর্তন'}: '),
              DropdownButton<String>(
                value: widget.order.status,
                items: ['pending', 'shipped', 'delivered', 'cancelled']
                    .map((status) {
                  final statusOptions = labelService.labels?['statusOptions']
                      as Map<String, dynamic>?;
                  final displayText = statusOptions?[status] ?? status;
                  return DropdownMenuItem(
                    value: status,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null && val != widget.order.status) {
                    Map<String, dynamic> updateData = {'status': val};
                    if (val == 'cancelled') {
                      updateData['cancelledBy'] = 'admin';
                      updateData['cancelledAt'] =
                          DateTime.now().toIso8601String();
                    }
                    controller.updateOrderStatusWithDetails(
                        widget.order.orderId, updateData);
                  }
                },
              ),
            ],
          ),
          Row(
            children: [
              Text(
                  '${labelService.getLabel('paymentSuccess') ?? 'পেমেন্ট সফল'}: '),
              Checkbox(
                value: widget.order.paymentStatus == 'success',
                onChanged: (checked) {
                  controller.updatePaymentStatus(
                      widget.order.orderId, checked ?? false);
                },
              ),
            ],
          ),
          const Divider(),
          ...widget.order.items.map<Widget>((item) {
            return ListTile(
              leading: (item['imageUrl'] != null &&
                      (item['imageUrl'] as String).isNotEmpty)
                  ? Image.network(
                      item['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    )
                  : null,
              title: Text('${item['name']} (${item['unit']})'),
              subtitle: Text(
                  '${item['company']} | ${labelService.getLabel('quantity') ?? 'Qty'}: ${item['quantity']} | ${labelService.getLabel('price') ?? 'Unit Price'}: ${item['price']}'),
              trailing: Text('${item['total']}'),
            );
          }),
          const Divider(),
          Text(
              '৳${labelService.getLabel('deliveryCharge') ?? 'Delivery Charge'}: ${widget.order.deliveryCharge}'),
          Text(
              '৳${labelService.getLabel('total') ?? 'Total'}: ${widget.order.total}'),
          Text(
              '৳${labelService.getLabel('grandTotal') ?? 'Grand Total'}: ${widget.order.grandTotal}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showDownloadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelService.getLabel('downloadOptions') ?? 'ডাউনলোড অপশন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(labelService.getLabel('downloadAsPDF') ??
                  'PDF হিসেবে ডাউনলোড'),
              onTap: () {
                Navigator.pop(context);
                _saveAsPDF(widget.order.orderId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelService.getLabel('shareOptions') ?? 'শেয়ার অপশন',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(
                  labelService.getLabel('shareAsPDF') ?? 'PDF হিসেবে শেয়ার'),
              onTap: () {
                Navigator.pop(context);
                _shareAsPDF(widget.order.orderId);
              },
            ),
          ],
        ),
      ),
    );
  }

  // প্রিন্ট ফাংশন যোগ করা হল
  void _printOrder() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
            content: Text(labelService.getLabel('preparingToPrint') ??
                'প্রিন্টের জন্য প্রস্তুত হচ্ছে...')),
      );

      final pdf = await _generatePdfDocument(widget.order.orderId);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        format: PdfPageFormat.a4.copyWith(
          marginLeft: 2 * PdfPageFormat.cm,
          marginRight: 2 * PdfPageFormat.cm,
          marginTop: 2 * PdfPageFormat.cm,
          marginBottom: 2 * PdfPageFormat.cm,
        ),
      );

      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
            content: Text(labelService.getLabel('printSuccess') ??
                'প্রিন্ট সফলভাবে পাঠানো হয়েছে')),
      );
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
            content: Text(
                '${labelService.getLabel('printError') ?? 'প্রিন্ট করতে সমস্যা হয়েছে'}: $e')),
      );
    }
  }

  // Helper function to load images from network
  Future<pw.ImageProvider?> _loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print('Error loading image: $e');
    }
    return null;
  }

  Future<pw.Document> _generatePdfDocument(String orderId) async {
    // বাংলা এবং ইংরেজি ফন্ট লোড করুন
    final bengaliFont = await FontHelper.getBengaliRegular();
    final bengaliBoldFont = await FontHelper.getBengaliBold();
    final englishFont = FontHelper.getEnglishRegular();
    final englishBoldFont = FontHelper.getEnglishBold();

    // Pre-load all product images
    List<pw.ImageProvider?> productImages = [];
    for (var item in widget.order.items) {
      final image = await _loadNetworkImage(item['imageUrl']);
      productImages.add(image);
    }

    // পিডিএফ ডকুমেন্ট তৈরি করুন
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          children: [
            pw.Center(
              child: MixedTextRenderer.render(
                labelService.getLabel('orderDetails') ?? 'Order Details',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
                bengaliFont: bengaliBoldFont,
                englishFont: englishBoldFont,
              ),
            ),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.Center(
              child: MixedTextRenderer.render(
                labelService.getLabel('thankYou') ?? 'Thank you.',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                bengaliFont: bengaliBoldFont,
                englishFont: englishBoldFont,
              ),
            ),
          ],
        ),
        build: (context) => [
          // Order Information
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                MixedTextRenderer.render(
                  '${labelService.getLabel('orderId') ?? 'Order ID'}: ${widget.order.orderId}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                  bengaliFont: bengaliBoldFont,
                  englishFont: englishBoldFont,
                ),
                MixedTextRenderer.render(
                  '${labelService.getLabel('placedAt') ?? 'Order time'}: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.order.placedAt)}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
                MixedTextRenderer.render(
                  '${labelService.getLabel('status') ?? 'Status'}: ${labelService.getLabel(widget.order.status) ?? widget.order.status}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
                if (widget.order.status == 'cancelled' &&
                    widget.order.cancelledBy != null)
                  MixedTextRenderer.render(
                    '${labelService.getLabel('cancelledBy') ?? 'বাতিল করেছেন'}: ${widget.order.cancelledBy == 'user' ? labelService.getLabel('user') ?? 'ইউজার' : labelService.getLabel('admin') ?? 'অ্যাডমিন'}',
                    bengaliFont: bengaliFont,
                    englishFont: englishFont,
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          // Customer Information
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                MixedTextRenderer.render(
                  labelService.getLabel('buyerInfo') ?? 'Buyer information',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                  bengaliFont: bengaliBoldFont,
                  englishFont: englishBoldFont,
                ),
                pw.SizedBox(height: 5),
                MixedTextRenderer.render(
                  '${labelService.getLabel('userName') ?? 'Name'}: ${widget.order.userName}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
                MixedTextRenderer.render(
                  '${labelService.getLabel('userPhone') ?? 'Phone'}: ${widget.order.userPhone}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          // Address
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                MixedTextRenderer.render(
                  labelService.getLabel('address') ?? 'Address',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                  bengaliFont: bengaliBoldFont,
                  englishFont: englishBoldFont,
                ),
                pw.SizedBox(height: 5),
                MixedTextRenderer.render(
                  '${widget.order.location['house'] ?? ''}, ${widget.order.location['ward'] ?? ''}, ${widget.order.location['road'] ?? ''}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
                MixedTextRenderer.render(
                  '${widget.order.location['village'] ?? ''}, ${widget.order.location['upazila']}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
                if (widget.order.location['union'] != null &&
                    (widget.order.location['union'] as String).isNotEmpty &&
                    (widget.order.location['union'] as String).toLowerCase() !=
                        'null')
                  MixedTextRenderer.render(
                    '${widget.order.location['union']}',
                    bengaliFont: bengaliFont,
                    englishFont: englishFont,
                  ),
                MixedTextRenderer.render(
                  '${widget.order.location['district']}, ${widget.order.location['division']}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
                if (widget.order.userGpsLocation != null &&
                    Uri.tryParse(widget.order.userGpsLocation!)
                            ?.hasAbsolutePath ==
                        true)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 5),
                    child: pw.UrlLink(
                      destination: widget.order.userGpsLocation!,
                      child: MixedTextRenderer.render(
                        'GPS Location: ${widget.order.userGpsLocation}',
                        style: pw.TextStyle(
                          color: PdfColors.blue,
                          decoration: pw.TextDecoration.underline,
                        ),
                        bengaliFont: bengaliFont,
                        englishFont: englishFont,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          // Special Message
          if (widget.order.specialMessage != null &&
              widget.order.specialMessage!.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.yellow50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.yellow200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  MixedTextRenderer.render(
                    labelService.getLabel('specialMessage') ??
                        'Special Message',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                    bengaliFont: bengaliBoldFont,
                    englishFont: englishBoldFont,
                  ),
                  pw.SizedBox(height: 5),
                  MixedTextRenderer.render(
                    widget.order.specialMessage!,
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                    ),
                    bengaliFont: bengaliFont,
                    englishFont: englishFont,
                  ),
                ],
              ),
            ),
          if (widget.order.specialMessage != null &&
              widget.order.specialMessage!.isNotEmpty)
            pw.SizedBox(height: 15),
          // Payment Information
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                MixedTextRenderer.render(
                  labelService.getLabel('paymentInfo') ?? 'Payment information',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                  bengaliFont: bengaliBoldFont,
                  englishFont: englishBoldFont,
                ),
                pw.SizedBox(height: 5),
                MixedTextRenderer.render(
                  '${labelService.getLabel('paymentMethod') ?? 'Payment Method'}: ${widget.order.paymentMethod}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
                MixedTextRenderer.render(
                  '${labelService.getLabel('paymentStatus') ?? 'Payment status'}: ${widget.order.paymentStatus}',
                  bengaliFont: bengaliFont,
                  englishFont: englishFont,
                ),
                if (widget.order.trxId.isNotEmpty)
                  MixedTextRenderer.render(
                    '${labelService.getLabel('trxId') ?? 'ট্রানজেকশন আইডি'}: ${widget.order.trxId}',
                    bengaliFont: bengaliFont,
                    englishFont: englishFont,
                  ),
                if (widget.order.userPaymentNumber.isNotEmpty)
                  MixedTextRenderer.render(
                    '${labelService.getLabel('userPaymentNumber') ?? 'পেমেন্ট নম্বর'}: ${widget.order.userPaymentNumber}',
                    bengaliFont: bengaliFont,
                    englishFont: englishFont,
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          // Product List
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                MixedTextRenderer.render(
                  labelService.getLabel('items') ?? 'Product List',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                  bengaliFont: bengaliBoldFont,
                  englishFont: englishBoldFont,
                ),
                pw.SizedBox(height: 10),
                // Product Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: pw.FixedColumnWidth(60),
                    1: pw.FlexColumnWidth(3),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FixedColumnWidth(60),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: MixedTextRenderer.render(
                            labelService.getLabel('photo') ?? 'Photo',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                            bengaliFont: bengaliBoldFont,
                            englishFont: englishBoldFont,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: MixedTextRenderer.render(
                            labelService.getLabel('productName') ??
                                'Product name',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                            bengaliFont: bengaliBoldFont,
                            englishFont: englishBoldFont,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: MixedTextRenderer.render(
                            labelService.getLabel('description') ??
                                'Description',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                            bengaliFont: bengaliBoldFont,
                            englishFont: englishBoldFont,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: MixedTextRenderer.render(
                            labelService.getLabel('total') ?? 'Total',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                            bengaliFont: bengaliBoldFont,
                            englishFont: englishBoldFont,
                          ),
                        ),
                      ],
                    ),
                    // Product Rows
                    ...widget.order.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final image = productImages[index];
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Center(
                              child: image != null
                                  ? pw.Image(image, width: 40, height: 40)
                                  : pw.Container(
                                      width: 40,
                                      height: 40,
                                      decoration: pw.BoxDecoration(
                                        color: PdfColors.grey200,
                                        borderRadius: const pw.BorderRadius.all(
                                            pw.Radius.circular(4)),
                                      ),
                                      child: pw.Center(
                                        child: MixedTextRenderer.render(
                                          labelService.getLabel('noImage') ??
                                              'ছবি নেই',
                                          style: pw.TextStyle(fontSize: 8),
                                          bengaliFont: bengaliFont,
                                          englishFont: englishFont,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                MixedTextRenderer.render(
                                  '${item['name']} (${item['unit']})',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  bengaliFont: bengaliBoldFont,
                                  englishFont: englishBoldFont,
                                ),
                                MixedTextRenderer.render(
                                  item['company'],
                                  bengaliFont: bengaliFont,
                                  englishFont: englishFont,
                                ),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: MixedTextRenderer.render(
                              '${labelService.getLabel('quantity') ?? 'Qty'}: ${item['quantity']} | ${item['price']}',
                              bengaliFont: bengaliFont,
                              englishFont: englishFont,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: MixedTextRenderer.render(
                              '৳${item['total']}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                              bengaliFont: bengaliBoldFont,
                              englishFont: englishBoldFont,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          // Price Information
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                MixedTextRenderer.render(
                  labelService.getLabel('priceInfo') ?? 'Price information',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                  bengaliFont: bengaliBoldFont,
                  englishFont: englishBoldFont,
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    MixedTextRenderer.render(
                      labelService.getLabel('subtotal') ?? 'Subtotal:',
                      bengaliFont: bengaliFont,
                      englishFont: englishFont,
                    ),
                    MixedTextRenderer.render(
                      '${widget.order.total}',
                      bengaliFont: bengaliFont,
                      englishFont: englishFont,
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    MixedTextRenderer.render(
                      labelService.getLabel('deliveryCharges') ??
                          'Delivery charges:',
                      bengaliFont: bengaliFont,
                      englishFont: englishFont,
                    ),
                    MixedTextRenderer.render(
                      '৳${widget.order.deliveryCharge}',
                      bengaliFont: bengaliFont,
                      englishFont: englishFont,
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    MixedTextRenderer.render(
                      labelService.getLabel('totalAmount') ?? 'Total:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                      bengaliFont: bengaliBoldFont,
                      englishFont: englishBoldFont,
                    ),
                    MixedTextRenderer.render(
                      '৳${widget.order.grandTotal}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                      bengaliFont: bengaliBoldFont,
                      englishFont: englishBoldFont,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _saveAsPDF(String orderId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
            content: Text(labelService.getLabel('pdfCreating') ??
                'পিডিএফ তৈরি হচ্ছে...')),
      );
      final pdf = await _generatePdfDocument(orderId);
      final bytes = await pdf.save();

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "$orderId.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
              content: Text(labelService.getLabel('downloadStarted') ??
                  'ডাউনলোড শুরু হয়েছে...')),
        );
      } else {
        // Request storage permission for Android
        if (Platform.isAndroid) {
          var status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(Get.context!).showSnackBar(
              SnackBar(
                  content: Text(labelService.getLabel('permissionDenied') ??
                      'স্টোরেজ পারমিশন দেওয়া হয়নি। ফাইল ডাউনলোড করা যাবে না।')),
            );
            return; // Exit if permission is not granted
          }
        }

        Directory? directory;
        if (Platform.isAndroid) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directory = Directory('${externalDir.path}/Download');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        } else if (Platform.isIOS) {
          directory =
              await getApplicationDocumentsDirectory(); // App's private documents
        }

        if (directory == null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
                content: Text(labelService.getLabel('directoryError') ??
                    'ডাউনলোড ডিরেক্টরি খুঁজে পাওয়া যায়নি।')),
          );
          return;
        }

        final file = File('${directory.path}/ORDER_$orderId.pdf');
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
              content: Text(
                  '${labelService.getLabel('savedAt') ?? 'সংরক্ষণ করা হয়েছে'}: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
            content: Text(
                '${labelService.getLabel('downloadError') ?? 'ডাউনলোড করতে সমস্যা হয়েছে'}: $e')),
      );
    }
  }

  Future<void> _shareAsPDF(String orderId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
            content: Text(labelService.getLabel('pdfCreating') ??
                'পিডিএফ তৈরি হচ্ছে...')),
      );
      final pdf = await _generatePdfDocument(orderId);
      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$orderId.pdf');
      await file.writeAsBytes(bytes);
      final xfile = XFile(file.path);
      await Share.shareXFiles([xfile], text: 'Order Details: $orderId');
      await file.delete();
    } catch (e) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
            content: Text(
                '${labelService.getLabel('shareError') ?? 'শেয়ার করতে সমস্যা হয়েছে'}: $e')),
      );
    }
  }
}
