import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aquí dejas también Firebase.initializeApp(...)
  // si ya lo tienes configurado.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const CampusSenseApp(),
    ),
  );
}

class CampusSenseApp extends StatelessWidget {
  const CampusSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Aquí va tu configuración actual de theme
      themeMode: themeProvider.themeMode,

      home: const YourInitialScreen(),
    );
  }
}