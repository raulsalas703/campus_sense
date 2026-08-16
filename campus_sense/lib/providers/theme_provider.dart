import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  late final StreamSubscription<User?> _authSubscription;

  ThemeProvider() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
    );
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _themeMode = ThemeMode.light;
      notifyListeners();
      return;
    }

    try {
      final documento = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final datos = documento.data();

      final tema = datos?['tema']?.toString() ?? 'light';

      if (tema == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }

      notifyListeners();
    } catch (_) {
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> cambiarTema(
    bool oscuro,
  ) async {
    final modoAnterior = _themeMode;

    _themeMode =
        oscuro ? ThemeMode.dark : ThemeMode.light;

    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'tema': oscuro ? 'dark' : 'light',
      }, SetOptions(merge: true));
    } catch (e) {
      _themeMode = modoAnterior;

      notifyListeners();

      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}