import 'package:flutter/material.dart';
import 'esquema_color.dart';

class ThemeGeneral {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: EsquemaColor.primary,
          secondary: EsquemaColor.accent,
          surface: EsquemaColor.surface,
          background: EsquemaColor.background,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: EsquemaColor.textPrimary,
          onBackground: EsquemaColor.textPrimary,
        ),
        scaffoldBackgroundColor: EsquemaColor.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: EsquemaColor.textPrimary,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: EsquemaColor.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        cardTheme: CardThemeData(
          color: EsquemaColor.card,
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: EsquemaColor.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EsquemaColor.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EsquemaColor.primary, width: 2)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(color: EsquemaColor.muted),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: EsquemaColor.primary,
          unselectedItemColor: EsquemaColor.muted,
          backgroundColor: Colors.white,
          elevation: 20,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
