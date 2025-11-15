import 'package:amar_uddokta/uddoktaa/controllers/OrderController.dart';
import 'package:amar_uddokta/madmin/models/order_model.dart';
import 'package:amar_uddokta/madmin/screens/admin_delivery_fee_screen.dart';
import 'package:amar_uddokta/uddoktaa/widgets/label_service.dart';
import 'package:amar_uddokta/uddoktaa/widgets/order_card.dart';
import 'package:amar_uddokta/uddoktaa/services/location_service.dart'; // Import LocationService

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class OrderAdminScreen extends StatefulWidget {
  const OrderAdminScreen({super.key});
  @override
  _OrderAdminScreenState createState() => _OrderAdminScreenState();
}

class _OrderAdminScreenState extends State<OrderAdminScreen> {
  final OrderController controller = Get.put(OrderController());
  final LabelService labelService = LabelService();
  bool _showTodayOrders = false;
  bool _showAllOrders = false;

  @override
  void initState() {
    super.initState();
    // Load labels when screen initializes
    labelService.loadLabels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            labelService.getLabel('orderManagement') ?? 'অর্ডার ম্যানেজমেন্ট'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: labelService.getLabel('refreshOrders') ?? 'Refresh Orders',
            onPressed: () {
              controller.fetchOrders();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ডিবাগিং তথ্য - মোট অর্ডার সংখ্যা দেখানো
              Obx(() => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: Colors.yellow.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${labelService.getLabel('totalOrders') ?? 'মোট অর্ডার'}: ${controller.allOrders.length}',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                '${labelService.getLabel('filteredOrders') ?? 'ফিল্টার করা অর্ডার'}: ${controller.filteredOrders.length}'),
                            Text(
                                '${labelService.getLabel('todayOrders') ?? 'আজকের অর্ডার'}: ${controller.todayOrders.length}'),
                            if (controller.isLoading.value)
                              Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 10),
                                  Text(labelService.getLabel('loading') ??
                                      'লোড হচ্ছে...'),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: labelService.getLabel('searchHint') ??
                        'নাম বা অর্ডার আইডি দিয়ে সার্চ করুন',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    controller.searchQuery.value = value;
                    controller.applyFilters();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Obx(
                      () => DropdownButton<String>(
                        hint: Text(
                            labelService.getLabel('status') ?? 'স্ট্যাটাস'),
                        value: controller.filterStatus.value.isEmpty
                            ? null
                            : controller.filterStatus.value,
                        items: [
                          '',
                          'pending',
                          'shipped',
                          'delivered',
                          'cancelled'
                        ].map((status) {
                          final display = status.isEmpty
                              ? labelService.getLabel('all') ?? 'সব'
                              : _statusText(status);
                          return DropdownMenuItem(
                            value: status,
                            child: Text(display),
                          );
                        }).toList(),
                        onChanged: (val) {
                          controller.filterStatus.value = val ?? '';
                          controller.applyFilters();
                        },
                      ),
                    ),
                    Obx(
                      () => DropdownButton<String>(
                        hint: Text(labelService.getLabel('paymentStatus') ??
                            'পেমেন্ট স্ট্যাটাস'),
                        value: controller.filterPaymentStatus.value.isEmpty
                            ? null
                            : controller.filterPaymentStatus.value,
                        items:
                            ['', 'pending', 'success', 'failed'].map((status) {
                          final display = status.isEmpty
                              ? labelService.getLabel('all') ?? 'সব'
                              : status;
                          return DropdownMenuItem(
                            value: status,
                            child: Text(display),
                          );
                        }).toList(),
                        onChanged: (val) {
                          controller.filterPaymentStatus.value = val ?? '';
                          controller.applyFilters();
                        },
                      ),
                    ),
                    DatePickerWidget(
                      label: labelService.getLabel('date') ?? 'তারিখ',
                      selectedDate: controller.filterDate.value,
                      onDateSelected: (date) {
                        controller.filterDate.value = date;
                        controller.applyFilters();
                      },
                      labelService: labelService,
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(_showTodayOrders
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                      label: Obx(() => Text(
                          '${labelService.getLabel('todaysOrders') ?? 'আজকের অর্ডার'} (${controller.todayOrders.length})')),
                      onPressed: () {
                        setState(() {
                          _showTodayOrders = !_showTodayOrders;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(_showAllOrders
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                      label: Obx(() => Text(
                          '${labelService.getLabel('allOrders') ?? 'সকল অর্ডার'} (${controller.allOrders.length})')),
                      onPressed: () {
                        setState(() {
                          _showAllOrders = !_showAllOrders;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showTodayOrders)
                Obx(() {
                  final orders = controller.todayOrders;
                  if (orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(labelService.getLabel('noTodaysOrders') ??
                          'আজকের কোনো অর্ডার পাওয়া যায়নি'),
                    );
                  }
                  return _buildOrdersList(
                      orders, Colors.orange[100] ?? Colors.orange);
                }),
              if (_showAllOrders)
                Obx(() {
                  final orders = controller.filteredOrders;
                  if (orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(labelService.getLabel('noOrdersFound') ??
                          'কোনো অর্ডার পাওয়া যায়নি'),
                    );
                  }
                  return _buildOrdersList(
                      orders, Colors.green[100] ?? Colors.green);
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, Color cardColor) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          color: cardColor,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ডিবাগিং তথ্য - অর্ডারের সময় ফিল্ড দেখানো
              Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        // সংশোধিত: placedAt ব্যবহার করা হচ্ছে
                        '${labelService.getLabel('orderTime') ?? 'অর্ডার সময়'}: ${DateFormat('yyyy-MM-dd HH:mm').format(order.placedAt)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              OrderCard(order: order, color: cardColor),
              if (order.userGpsLocation != null &&
                  Uri.tryParse(order.userGpsLocation!)?.hasAbsolutePath == true)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: InkWell(
                    onTap: () =>
                        LocationService.launchMapUrl(order.userGpsLocation!),
                    child: Text(
                      'GPS Location: ${order.userGpsLocation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _statusText(String status) {
    final statusOptions =
        labelService.labels?['statusOptions'] as Map<String, dynamic>?;
    return statusOptions?[status] ?? status;
  }
}

class DatePickerWidget extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final void Function(DateTime?) onDateSelected;
  final LabelService labelService;

  const DatePickerWidget({
    Key? key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    required this.labelService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    String displayText =
        selectedDate == null ? label : formatter.format(selectedDate!);
    return Row(
      children: [
        InkWell(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            onDateSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(displayText),
          ),
        ),
        if (selectedDate != null)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => onDateSelected(null),
          ),
      ],
    );
  }
}
