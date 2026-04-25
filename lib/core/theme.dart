import 'package:flutter/material.dart';

/// Kinsu Health design system — colors, typography, and component themes
/// aligned with the 0.3.0 visual redesign reference.
class KinsuTheme {
  KinsuTheme._();

  // ── Brand Colors ───────────────────────────────────
  static const Color primary = Color(0xFF309BD3);
  static const Color primaryDark = Color(0xFF1F7BAA);
  static const Color primaryLight = Color(0xFFE1F0F8);
  static const Color accent = Color(0xFFFFF489);

  // ── Border Radii ────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;

  // ── Status Colors ──────────────────────────────────
  static const Color statusActive = Color(0xFF0CA508);
  static const Color success = Color(0xFF0CA508);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFFE5A61);
  static const Color destructive = Color(0xFFFE5A61);
  static const Color statusInfo = Color(0xFF309BD3);

  // ── Neutral Colors ─────────────────────────────────
  static const Color background = Color(0xFFF5F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color panel = Color(0xFFF7F6F2);
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFFA7A6A3);
  static const Color divider = Color(0xFFE0DCD5);
  static const Color border = Color(0xFFE0DCD5);

  // ── Card Style ─────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: primaryLight,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: divider),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: primaryLight,
          selectedColor: primary,
          labelStyle: const TextStyle(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101418),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101418),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF182029),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF101418),
          selectedItemColor: primary,
          unselectedItemColor: Color(0xFF9CA3AF),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );
}

/// Spacing scale used across Kinsu Health UI.
///
/// Use these constants instead of raw numbers so adjusting the design
/// system is a single-file change.
class KinsuSpacing {
  KinsuSpacing._();

  /// 4 dp — micro gap (icon ↔ label, tight inline pairs)
  static const double xs = 4.0;

  /// 8 dp — small gap (between related items in a card)
  static const double sm = 8.0;

  /// 12 dp — medium gap (card internal padding, between sections)
  static const double md = 12.0;

  /// 16 dp — large gap (screen horizontal padding, between cards)
  static const double lg = 16.0;

  /// 20 dp — extra-large gap (section separators)
  static const double xl = 20.0;

  /// 24 dp — 2× large (bottom safe-area padding, modal headers)
  static const double xxl = 24.0;

  /// 32 dp — used for empty-state and onboarding vertical breathing room
  static const double xxxl = 32.0;
}
