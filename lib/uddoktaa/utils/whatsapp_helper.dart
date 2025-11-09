import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:amar_uddokta/uddoktaa/controllers/WhatsappNumberController.dart';

Future<void> openWhatsApp(BuildContext context) async {
  final WhatsappNumberController whatsappNumberController = Get.find();
  final phoneNumber = whatsappNumberController.whatsappNumber.value;
  const message = 'হ্যালো! আমি আপনার দোকানের বিষয়ে জানতে চাচ্ছি।';

  if (phoneNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp নম্বর পাওয়া যায়নি।')),
    );
    return;
  }

  final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
  final Uri whatsappUri = Uri.parse(url);

  try {
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('WhatsApp খোলা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ত্রুটি: ${e.toString()}')),
    );
  }
}
