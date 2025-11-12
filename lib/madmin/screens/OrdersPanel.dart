// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/export_service.dart';

class OrdersPanel extends StatefulWidget {
  const OrdersPanel({super.key});

  @override
  State<OrdersPanel> createState() => _OrdersPanelState();
}

class _OrdersPanelState extends State<OrdersPanel> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  String _statusFilter = 'All';
  String _paymentStatusFilter = 'All';
  DateTimeRange? _selectedDateRange;
  final int _limit = 10;
  Map<String, dynamic>? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isAscending = false;
  String _sortField = 'placedAt'; // Changed to placedAt

  int totalOrders = 0;
  int pendingOrders = 0;
  int successOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final response = await _supabase.from('orders').select();
    totalOrders = response.length;
    pendingOrders = response.where((d) => d['status'] == 'pending').length;
    successOrders =
        response.where((d) => d['paymentStatus'] == 'success').length;
    setState(() {});
  }

  Future<void> _fetchOrders({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset)) return;
    setState(() => _isLoading = true);

    PostgrestFilterBuilder<PostgrestList> filterBuilder =
        _supabase.from('orders').select();

    if (_statusFilter != 'All') {
      filterBuilder = filterBuilder.eq('status', _statusFilter);
    }
    if (_paymentStatusFilter != 'All') {
      filterBuilder = filterBuilder.eq('paymentStatus', _paymentStatusFilter);
    }
    if (_selectedDateRange != null) {
      filterBuilder = filterBuilder.gte(
          'placedAt', _selectedDateRange!.start.toIso8601String());
      filterBuilder = filterBuilder.lte(
          'placedAt', _selectedDateRange!.end.toIso8601String());
    }

    // Apply pagination after initial filters
    if (_lastDocument != null && !reset) {
      filterBuilder = filterBuilder.gt('id', _lastDocument!['id']);
    }

    // Apply sorting and limiting to get a PostgrestTransformBuilder
    PostgrestTransformBuilder<PostgrestList> transformedQuery =
        filterBuilder.order(_sortField, ascending: _isAscending).limit(_limit);

    if (reset) {
      _orders.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    final response = await transformedQuery;
    if (response.isNotEmpty) {
      _orders.addAll((response as List).cast<Map<String, dynamic>>());
      _lastDocument = _orders.last;
    } else {
      _hasMore = false;
    }
    setState(() => _isLoading = false);
  }

  void _changeStatus(Map<String, dynamic> order, String newStatus) async {
    await _supabase
        .from('orders')
        .update({'status': newStatus}).eq('orderId', order['orderId']);

    // Fetch the updated document from Supabase
    final response = await _supabase
        .from('orders')
        .select()
        .eq('orderId', order['orderId'])
        .single();

    final index = _orders.indexOf(order);
    if (index != -1) {
      List<Map<String, dynamic>> newOrders =
          List<Map<String, dynamic>>.from(_orders);
      newOrders[index] = response;

      setState(() {
        _orders = newOrders;
      });
    }
      _fetchSummary();
  }

  Widget _buildFilterControls() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        DropdownButton<String>(
          value: _statusFilter,
          items: ['All', 'pending', 'confirmed', 'shipped', 'delivered']
              .map((e) => DropdownMenuItem(value: e, child: Text('Status: $e')))
              .toList(),
          onChanged: (value) {
            _statusFilter = value!;
            _fetchOrders(reset: true);
          },
        ),
        DropdownButton<String>(
          value: _paymentStatusFilter,
          items: ['All', 'pending', 'success', 'failed']
              .map(
                  (e) => DropdownMenuItem(value: e, child: Text('Payment: $e')))
              .toList(),
          onChanged: (value) {
            _paymentStatusFilter = value!;
            _fetchOrders(reset: true);
          },
        ),
        ElevatedButton(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2024, 1),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              _selectedDateRange = picked;
              _fetchOrders(reset: true);
            }
          },
          child: Text(_selectedDateRange == null
              ? 'Date Filter'
              : '${DateFormat.yMd().format(_selectedDateRange!.start)} - ${DateFormat.yMd().format(_selectedDateRange!.end)}'),
        ),
        ElevatedButton(
          onPressed: () {
            _selectedDateRange = null;
            _statusFilter = 'All';
            _paymentStatusFilter = 'All';
            _fetchOrders(reset: true);
          },
          child: Text('Clear All'),
        )
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCard('Total', totalOrders),
        _buildCard('Pending', pendingOrders),
        _buildCard('Success', successOrders),
      ],
    );
  }

  Widget _buildCard(String title, int count) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(count.toString(), style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    return ListTile(
      title: Text('${order['userName']} (${order['userPhone']})'),
      subtitle: Text(
        '${order['orderId']}\n৳${(order['grandTotal'] as num?)?.toDouble() ?? 0.0} - ${order['status']} - ${order['paymentStatus']}\n${DateFormat.yMd().add_jm().format(DateTime.parse(order['placedAt']))}',
      ),
      trailing: DropdownButton<String>(
        value: order['status'],
        items: ['pending', 'confirmed', 'shipped', 'delivered']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (value) => _changeStatus(order, value!),
      ),
    );
  }

  Widget _buildSortHeader(String field, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortField == field) {
            _isAscending = !_isAscending;
          } else {
            _sortField = field;
            _isAscending = true;
          }
          _fetchOrders(reset: true);
        });
      },
      child: Row(
        children: [
          Text(label),
          if (_sortField == field)
            Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Orders')),
      body: Column(
        children: [
          SizedBox(height: 8),
          _buildSummaryCards(),
          SizedBox(height: 8),
          _buildFilterControls(),
          Divider(),
          _buildSortHeader('placedAt', 'Date'),
          Expanded(
            child: ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) => _buildOrderRow(_orders[index]),
            ),
          ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _fetchOrders,
                child: Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }
}
