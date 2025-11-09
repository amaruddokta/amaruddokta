import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'my_home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      enableScaleText: () => false,
      minTextAdapt: true,
      designSize: const Size(392.72727272727275, 800.7272727272727),
      builder: (context, c) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1),
          ),
          child: Platform.isIOS
              ? CupertinoApp(title: 'Quran qcf Demo', home: const MyHomePage())
              : MaterialApp(title: 'Quran qcf Demo', home: const MyHomePage()),
        );
      },
    );
  }
}