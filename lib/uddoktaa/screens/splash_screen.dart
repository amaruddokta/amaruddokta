import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amar_uddokta/uddoktaa/services/user_prefs.dart';
import 'package:amar_uddokta/uddoktaa/models/user.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/image/আমার উদ্যোক্তা আমার গর্ব.png',
          width: MediaQuery.of(context).size.width,
          height: 300,
        ),
      ),
    );
  }
}
