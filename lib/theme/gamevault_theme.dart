import 'package:flutter/material.dart';

class GameVaultTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF101418),
        onSurface: Colors.white,
        primary: Color(0xFFD500F9),
      ),
      scaffoldBackgroundColor: const Color(0xFF101418),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101418),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: Color(0xFFD500F9),
        labelColor: Color(0xFFD500F9),
        unselectedLabelColor: Colors.white60,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2228),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIconColor: const Color(0xFFD500F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD500F9), width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD500F9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }
}