// ignore_for_file: unused_import

import 'package:amar_uddokta/Quran/my_app.dart' as quran_app;
import 'package:amar_uddokta/uddoktaa/controllers/cart_controller.dart';
import 'package:amar_uddokta/uddoktaa/controllers/ProductController.dart';
import 'package:amar_uddokta/uddoktaa/controllers/favorite_controller.dart';

import 'package:amar_uddokta/uddoktaa/services/user_prefs.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:amar_uddokta/uddoktaa/screens/splash_screen.dart';
import 'package:amar_uddokta/uddoktaa/screens/registration_screen.dart';
import 'package:amar_uddokta/uddoktaa/screens/home_screen.dart' as home;
import 'package:amar_uddokta/uddoktaa/screens/profile_screen.dart'
    as app_profile;
import 'package:amar_uddokta/uddoktaa/screens/cart_screen.dart';
import 'package:amar_uddokta/uddoktaa/screens/favorite_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amar_uddokta/madmin/screens/admin_delivery_fee_screen.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url:
        'https://sqemidvbhptlmakfcnzk.supabase.co', // Replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxZW1pZHZiaHB0bG1ha2ZjbnprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMjA2MjQsImV4cCI6MjA3Nzg5NjYyNH0.Hvq5DrlP60Ly51JLHeaTj2BNDdPoJ0OFPDkaL4La-SA', // Replace with your Supabase anon key
  );

  // Controller গুলো এখানে ইনজেক্ট করো যাতে পুরো অ্যাপ থেকে সহজে ইউজ করা যায়
  Get.put(CartController());
  Get.put(ProductController());
  Get.put(ProductController());

  Get.put(FavoriteController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(360, 690),
    ); // Initialize ScreenUtil
    return ResponsiveBreakpoints.builder(
      breakpoints: [
        const Breakpoint(start: 0, end: 450, name: MOBILE),
        const Breakpoint(start: 451, end: 800, name: TABLET),
        const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'আমার দোকান',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'NotoSansBengali',
          textTheme: GoogleFonts.notoSansBengaliTextTheme(),
        ),
        initialRoute: '/', // Splash screen থেকে শুরু
        getPages: [
          GetPage(name: '/', page: () => SplashScreen()),
          GetPage(name: '/register', page: () => RegistrationScreen()),
          GetPage(
            name: '/home',
            page: () => home.HomeScreen(),
          ), // মূল অ্যাপের হোম স্ক্রিন
          GetPage(
            name: '/Quran',
            page: () => quran_app.MyApp(),
          ), // কুরআন অ্যাপের হোম স্ক্রিন
          GetPage(
            name: '/profile',
            page: () => app_profile.ProfileScreen(),
          ),
          GetPage(name: '/cart', page: () => CartScreen()),
          GetPage(name: '/favorite', page: () => FavoriteScreen()),
          GetPage(
            name: '/admin_delivery_fee',
            page: () => AdminDeliveryFeeScreen(),
          ),
        ],
      ),
    );
  }
}
