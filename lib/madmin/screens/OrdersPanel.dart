// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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
  int _limit = 10;
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isAscending = false;
  String _sortField = 'placed_at';

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
    final snapshot = await _supabase.from('orders').select('count');
    totalOrders = snapshot.length;

    final pendingSnapshot =
        await _supabase.from('orders').select('count').eq('status', 'pending');
    pendingOrders = pendingSnapshot.length;

    final successSnapshot = await _supabase
        .from('orders')
        .select('count')
        .eq('payment_status', 'success');
    successOrders = successSnapshot.length;

    setState(() {});
  }

  Future<void> _fetchOrders({bool reset = false}) async {
    if (_isLoading || !_hasMore && !reset) return;
    setState(() => _isLoading = true);

    var query = _supabase.from('orders').select('*');

    if (_statusFilter != 'All') {
      query = query.eq('status', _statusFilter);
    }
    if (_paymentStatusFilter != 'All') {
      query = query.eq('payment_status', _paymentStatusFilter);
    }
    if (_selectedDateRange != null) {
      query =
          query.gte('placed_at', _selectedDateRange!.start.toIso8601String());
      query = query.lte('placed_at', _selectedDateRange!.end.toIso8601String());
    }

    var orderedQuery = query.order(_sortField, ascending: _isAscending);
    var limitedQuery = orderedQuery.limit(_limit);

    if (!reset && _offset > 0) {
      limitedQuery = limitedQuery.range(_offset, _offset + _limit - 1);
    }

    final response = await limitedQuery;
    final newOrders = List<Map<String, dynamic>>.from(response);

    if (reset) {
      _orders = newOrders;
      _offset = 0;
      _hasMore = true;
    } else {
      _orders.addAll(newOrders);
      _offset += _limit;
    }

    if (newOrders.length < _limit) {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  void _changeStatus(Map<String, dynamic> order, String newStatus) async {
    await _supabase
        .from('orders')
        .update({'status': newStatus}).eq('order_id', order['order_id']);

    // Fetch the updated document from Supabase
    final response = await _supabase
        .from('orders')
        .select('*')
        .eq('order_id', order['order_id'])
        .single();

    final updatedOrder = Map<String, dynamic>.from(response);

    final index = _orders.indexWhere((o) => o['order_id'] == order['order_id']);
    if (index != -1) {
      setState(() {
        _orders[index] = updatedOrder;
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
      title: Text('${order['user_name']} (${order['user_phone']})'),
      subtitle: Text(
        '${order['order_id']}\n৳${order['grand_total']} - ${order['status']} - ${order['payment_status']}\n${DateFormat.yMd().add_jm().format(DateTime.parse(order['placed_at']))}',
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
          _buildSortHeader('placed_at', 'Date'),
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
