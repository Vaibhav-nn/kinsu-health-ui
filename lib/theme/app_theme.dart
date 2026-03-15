import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette from Figma Design
  static const Color background = Color(0xFFF8FAFB);
  static const Color foreground = Color(0xFF1A1D29);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF1A1D29);
  
  static const Color primary = Color(0xFF0A9B8F);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  
  static const Color secondary = Color(0xFFF0F7F6);
  static const Color secondaryForeground = Color(0xFF0A9B8F);
  
  static const Color muted = Color(0xFFF1F3F5);
  static const Color mutedForeground = Color(0xFF6B7280);
  
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentForeground = Color(0xFFFFFFFF);
  
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  
  static const Color border = Color(0xFFE5E7EB);
  static const Color inputBackground = Color(0xFFF3F4F6);
  
  // Document type colors
  static const Color labReportColor = Color(0xFF0A9B8F);
  static const Color prescriptionColor = Color(0xFF3B82F6);
  static const Color imagingColor = Color(0xFF8B5CF6);
  static const Color dischargeSummaryColor = Color(0xFFF59E0B);
  static const Color handwrittenColor = Color(0xFF6B7280);
  
  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        surface: card,
        onSurface: foreground,
        error: destructive,
        onError: destructiveForeground,
        outline: border,
        outlineVariant: border,
        surfaceContainerLowest: background,
        surfaceContainerHighest: muted,
        primaryContainer: secondary,
        onPrimaryContainer: secondaryForeground,
        secondaryContainer: muted,
        onSecondaryContainer: mutedForeground,
        onSurfaceVariant: mutedForeground,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: background,
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: card,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
      
      // Card theme
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: destructive, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: mutedForeground,
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: muted,
          foregroundColor: mutedForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        // Headlines
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        
        // Titles
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        
        // Body
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: foreground,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: mutedForeground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: mutedForeground,
        ),
        
        // Labels
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mutedForeground,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: mutedForeground,
        ),
      ),
    );
  }
  
  // Helper method to get document type color
  static Color getDocumentTypeColor(String recordType) {
    final type = recordType.toLowerCase();
    if (type.contains('lab') || type.contains('blood') || type.contains('cbc')) {
      return labReportColor;
    } else if (type.contains('prescription') || type.contains('medication')) {
      return prescriptionColor;
    } else if (type.contains('x-ray') || type.contains('mri') || 
               type.contains('ct') || type.contains('imaging')) {
      return imagingColor;
    } else if (type.contains('discharge') || type.contains('summary')) {
      return dischargeSummaryColor;
    }
    return handwrittenColor;
  }
  
  // Helper method to get document type icon
  static IconData getDocumentTypeIcon(String recordType) {
    final type = recordType.toLowerCase();
    if (type.contains('lab') || type.contains('blood') || type.contains('cbc')) {
      return Icons.science_outlined;
    } else if (type.contains('prescription') || type.contains('medication')) {
      return Icons.medical_services_outlined;
    } else if (type.contains('x-ray') || type.contains('mri') || 
               type.contains('ct') || type.contains('imaging')) {
      return Icons.image_outlined;
    } else if (type.contains('discharge') || type.contains('summary')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}
