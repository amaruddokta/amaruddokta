// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:amar_uddokta/madmin/screens/admin_dashboard_screen.dart';

import 'package:amar_uddokta/uddoktaa/screens/TermsApp.dart';
import 'package:amar_uddokta/uddoktaa/screens/about_screen.dart';
import 'package:amar_uddokta/uddoktaa/screens/registration_screen.dart';

// Import shared_preferences
// Import Login screen

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/user_prefs.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Removed Get.put(AdminOfferController()); to test if it interferes with navigation
    return Drawer(
      child: FutureBuilder<User?>(
        future: UserPrefs.getUser(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.deepPurple),
                  child: Center(
                    child: Text(
                      'স্বাগতম, গ্রাহক!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('হোম'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.menu_book),
                  title: Text('কুরআন শরীফ'),
                  onTap: () {
                    // Reverting to original Get.toNamed('/quran') as it was the intended route
                    Get.toNamed('/Quran');
                    // Navigator.pop(context); // Drawer will be closed by GetX navigation if configured
                  },
                ),
                ListTile(
                  leading: Icon(Icons.policy),
                  title: Text('Privacy Policy and Terms'),
                  onTap: () {
                    Get.to(() => TermsApp());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.policy),
                  title: Text('Privacy Policy and Terms'),
                  onTap: () {
                    Get.to(() => RegistrationScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                  onTap: () {
                    Get.to(() => AboutScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_offer),
                  title: Text('AdminDashboardScreen'),
                  onTap: () {
                    Get.to(() => AdminDashboardScreen());
                  },
                ),
              ],
            );
          }
          final user = snap.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.deepPurple),
                accountName: Text('স্বাগতম, ${user.name}'),
                accountEmail: Text(user.phone),
                currentAccountPicture: GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/profile'),
                  child: CircleAvatar(
                    backgroundImage:
                        user.imageUrl != null && user.imageUrl!.isNotEmpty
                            ? NetworkImage(user.imageUrl!) as ImageProvider
                            : const AssetImage('assets/image/default_user.png')
                                as ImageProvider,
                    child: user.imageUrl == null || user.imageUrl!.isEmpty
                        ? Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('হোম'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.menu_book),
                title: Text('কুরআন শরীফ'),
                onTap: () {
                  // Reverting to original Get.toNamed('/quran') as it was the intended route
                  Get.toNamed('/Quran');
                  // Navigator.pop(context); // Drawer will be closed by GetX navigation if configured
                },
              ),
              ListTile(
                leading: Icon(Icons.policy),
                title: Text('Privacy Policy and Terms'),
                onTap: () {
                  Get.to(() => TermsApp());
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap: () {
                  Get.to(() => AboutScreen());
                },
              ),
              ListTile(
                leading: Icon(Icons.local_offer),
                title: Text('AdminDashboardScreen'),
                onTap: () {
                  Get.to(() => AdminDashboardScreen());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
