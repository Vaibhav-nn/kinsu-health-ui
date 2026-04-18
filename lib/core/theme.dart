import 'package:flutter/material.dart';

class KinsuTheme {
  KinsuTheme._();

  static const Color primary = Color(0xFF0F9A96);
  static const Color primaryDark = Color(0xFF075A62);
  static const Color primaryLight = Color(0xFFE3F3F1);
  static const Color accent = Color(0xFF0F9A96);

  static const Color statusActive = Color(0xFF16A34A);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusInfo = Color(0xFF3B82F6);

  static const Color background = Color(0xFFF2F5F5);
  static const Color surface = Colors.white;
  static const Color panel = Color(0xFFEFF4F4);
  static const Color textPrimary = Color(0xFF1D2234);
  static const Color textSecondary = Color(0xFF6B7486);
  static const Color divider = Color(0xFFDDE4EA);
  static const Color border = divider;

  // ── Spacing scale ───────────────────────────────────────────────────────────
  /// 4 px — micro gap between tightly related elements (e.g. icon + label)
  static const double spaceXXS = 4;
  /// 8 px — small internal padding / tight vertical rhythm
  static const double spaceXS = 8;
  /// 12 px — standard item gap in a list or form
  static const double spaceSM = 12;
  /// 16 px — default horizontal screen margin / card internal padding
  static const double spaceMD = 16;
  /// 20 px — section gap or comfortable horizontal margin
  static const double spaceLG = 20;
  /// 24 px — large section separator
  static const double spaceXL = 24;
  /// 32 px — extra-large separation between major sections
  static const double spaceXXL = 32;

  /// Default horizontal content inset used on every screen.
  static const EdgeInsets screenPaddingH =
      EdgeInsets.symmetric(horizontal: spaceMD);
  /// Standard card internal padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceMD);
  /// Standard page padding (horizontal + vertical).
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceLG);

  // ── Border radii ────────────────────────────────────────────────────────────
  static const double radiusSM = 12;
  static const double radiusMD = 16;
  static const double radiusLG = 20;
  static const double radiusXL = 24;

  // ── Card decoration ─────────────────────────────────────────────────────────

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: surface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
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
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: divider),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: const TextStyle(color: Color(0xFF9CA8B7)),
          labelStyle: const TextStyle(color: textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.6),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: panel,
          selectedColor: primaryLight,
          labelStyle: const TextStyle(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: divider),
          ),
        ),
      );

  static ThemeData get darkTheme => lightTheme;
}
