// ignore_for_file: unused_import

import 'package:amar_uddokta/madmin/screens/comment_admin_panel.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'AdminSubItemPanell.dart';
import 'MarqueeEditor.dart';

import 'OrderAdminScreen.dart';
import 'OrdersExportPanel.dart';

import 'about_admin_screen.dart';
import 'admin_delivery_fee_screen.dart';
import 'call_number_admin_screen.dart';
import 'category_admin_screen.dart';
import 'notification_admin_screen.dart';
import 'terms_admin_screen.dart';

import 'AdminUserList.dart';
import 'SalesDetailScreen.dart';
import 'DashboardCard.dart';

const double DESKTOP = 800;

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'অ্যাডমিন ড্যাশবোর্ড',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard summary cards
              ResponsiveRowColumn(
                rowCrossAxisAlignment: CrossAxisAlignment.start,
                columnCrossAxisAlignment: CrossAxisAlignment.start,
                layout: ResponsiveBreakpoints.of(context).screenWidth < DESKTOP
                    ? ResponsiveRowColumnType.COLUMN
                    : ResponsiveRowColumnType.ROW,
                children: [
                  ResponsiveRowColumnItem(
                    rowFlex: 1,
                    child: _buildStatCard(
                      context,
                      title: 'মোট অর্ডার',
                      future: getTotalOrdersCount(),
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.indigo,
                    ),
                  ),
                  ResponsiveRowColumnItem(
                    rowFlex: 1,
                    child: _buildStatCard(
                      context,
                      title: 'মোট ইউজার',
                      future: getTotalUsersCount(),
                      icon: Icons.people_alt_outlined,
                      color: Colors.deepPurple,
                    ),
                  ),
                  ResponsiveRowColumnItem(
                    rowFlex: 1,
                    child: _buildSalesCard(
                      context,
                      title: 'আজকের বিক্রি',
                      future: getTodaySalesAmount(),
                      icon: Icons.attach_money_outlined,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Section title
              const Text(
                "অ্যাডমিন প্যানেল মেনুসমূহ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Grid menu section
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 600
                      ? 2
                      : constraints.maxWidth < 900
                          ? 3
                          : 4;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _menuButton(context, 'অর্ডার লিস্ট', Icons.list_alt,
                          OrderAdminScreen()),
                      _menuButton(context, 'অর্ডার এক্সপোর্ট',
                          Icons.file_download, OrdersExportPanel()),
                      _menuButton(context, 'ইউজার লিস্ট', Icons.people,
                          UserListScreen()),
                      _menuButton(context, 'Notice', Icons.campaign_outlined,
                          MarqueeEditor()),
                      _menuButton(context, 'SubItem', Icons.category_outlined,
                          AdminSubItemPanel()),
                      _menuButton(
                          context,
                          'Delivery Fee',
                          Icons.delivery_dining_outlined,
                          AdminDeliveryFeeScreen()),
                      _menuButton(context, 'Terms', Icons.description_outlined,
                          TermsAdminScreen()),
                      _menuButton(context, 'About', Icons.info_outline,
                          AboutAdminScreen()),
                      _menuButton(context, 'Call Number', Icons.call,
                          CallNumberAdminScreen()),
                      _menuButton(
                          context,
                          'Notification',
                          Icons.notifications_active_outlined,
                          NotificationAdminScreen()),
                      _menuButton(context, 'Comment', Icons.comment,
                          CommentAdminPanel()),
                      _menuButton(
                          context,
                          'Category',
                          Icons.dashboard_customize_outlined,
                          CategoryAdminScreen()),
                      _menuButton(context, 'বিক্রির বিস্তারিত',
                          Icons.bar_chart_outlined, SalesDetailScreen()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Stat cards with animation
  Widget _buildStatCard(BuildContext context,
      {required String title,
      required Future<int> future,
      required IconData icon,
      required Color color}) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final value = snapshot.hasData ? snapshot.data.toString() : '...';
        return _animatedCard(
          color,
          icon,
          title,
          value,
        );
      },
    );
  }

  Widget _buildSalesCard(BuildContext context,
      {required String title,
      required Future<double> future,
      required IconData icon,
      required Color color}) {
    return FutureBuilder<double>(
      future: future,
      builder: (context, snapshot) {
        final value =
            snapshot.hasData ? '৳ ${snapshot.data!.toStringAsFixed(2)}' : '...';
        return _animatedCard(color, icon, title, value);
      },
    );
  }

  Widget _animatedCard(Color color, IconData icon, String title, String value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 20, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuButton(
      BuildContext context, String title, IconData icon, Widget screen) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _exportOrdersToPdf() {
    debugPrint('Exporting orders to PDF...');
  }

  void _exportOrdersToExcel() {
    debugPrint('Exporting orders to Excel...');
  }
}

// === Database Queries ===
Future<int> getTotalOrdersCount() async {
  final response = await Supabase.instance.client.from('orders').select('*');
  return response.length;
}

Future<int> getTotalUsersCount() async {
  final response = await Supabase.instance.client.from('users').select('*');
  return response.length;
}

Future<double> getTodaySalesAmount() async {
  final today = DateTime.now();
  final startOfDay =
      DateTime(today.year, today.month, today.day).toIso8601String();
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
      .toIso8601String();

  final response = await Supabase.instance.client
      .from('orders')
      .select('totalAmount')
      .gte('timestamp', startOfDay)
      .lte('timestamp', endOfDay);

  double total = 0.0;
  for (var order in response) {
    final amount = order['totalAmount'] ?? 0;
    total += (amount is int) ? amount.toDouble() : amount;
  }

  return total;
}
