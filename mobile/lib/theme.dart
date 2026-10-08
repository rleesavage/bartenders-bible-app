import 'package:flutter/material.dart';

class BbColors {
  static const parchment = Color(0xfff2e3bc);
  static const parchmentLight = Color(0xfffff7df);
  static const parchmentDeep = Color(0xffdec48b);
  static const brown = Color(0xff3b2416);
  static const brown2 = Color(0xff5a351c);
  static const brown3 = Color(0xff704624);
  static const gold = Color(0xffb88a34);
  static const goldLight = Color(0xffffd777);
  static const ink = Color(0xff2e2118);
  static const muted = Color(0xff735e49);
}

ThemeData bbTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BbColors.brown,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: BbColors.parchment,
    colorScheme: scheme.copyWith(
      primary: BbColors.brown,
      secondary: BbColors.gold,
      surface: BbColors.parchmentLight,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: BbColors.ink,
        fontFamily: 'serif',
        fontSize: 16,
        height: 1.38,
      ),
      bodySmall: TextStyle(
        color: BbColors.muted,
        fontFamily: 'serif',
        fontSize: 13,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        color: BbColors.brown,
        fontFamily: 'serif',
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: BbColors.brown,
        fontFamily: 'serif',
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: BbColors.brown,
        fontFamily: 'serif',
        fontWeight: FontWeight.bold,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: BbColors.gold,
      thickness: 0.8,
    ),
    cardTheme: CardThemeData(
      color: BbColors.parchmentLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: BbColors.gold),
        borderRadius: BorderRadius.circular(5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BbColors.parchmentLight,
      labelStyle: const TextStyle(color: BbColors.brown),
      hintStyle: const TextStyle(color: BbColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: BbColors.gold),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: BbColors.gold),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: BbColors.brown, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BbColors.brown,
        foregroundColor: BbColors.goldLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
