import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import 'theme.dart';

class CampusSenseApp extends StatefulWidget {
  const CampusSenseApp({super.key});

  @override
  State<CampusSenseApp> createState() => _CampusSenseAppState();
}

class _CampusSenseAppState extends State<CampusSenseApp> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  bool get _isNight {
    final hour = DateTime.now().hour;

    return hour >= 19 || hour < 6;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusSense',

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: _isNight
          ? ThemeMode.dark
          : ThemeMode.light,

      home: const HomeScreen(),
    );
  }
}