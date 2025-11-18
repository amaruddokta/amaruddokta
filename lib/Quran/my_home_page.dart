import 'package:flutter/material.dart';
import 'quran_home_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // উইজেট বিল্ড হওয়ার পর সরাসরি QuranHomePage এ নেভিগেট করুন
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const QuranHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // এখানে আপনি একটি লোডিং ইন্ডিকেটর দেখাতে পারেন যখন নেভিগেশন হচ্ছে
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
