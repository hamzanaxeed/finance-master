import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false);

  void toggle() {
    state = !state;
  }

  void setDarkMode(bool value) {
    state = value;
  }
}

class AppTheme {
  // Brand color design tokens (Modern Premium Fintech)
  static const Color _primaryTeal = Color(0xFF0EA5A4);
  static const double _cornerRadius = 16.0;

  // Semantic Slate colors for perfect UI layering
  static const Color _slate50  = Color(0xFFF8FAFC); // Light Screen Background
  static const Color _slate100 = Color(0xFFF1F5F9); // Light Borders / Inputs
  static const Color _slate800 = Color(0xFF1E293B); // Dark Cards / Surfaces
  static const Color _slate900 = Color(0xFF0F172A); // Dark Screen Background

  static ThemeData _baseTheme(ColorScheme scheme) {
    final roundedBorder = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cornerRadius));

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface, // Clean canvas architecture
      primaryColor: scheme.primary,

      // Flat, clean modern App bar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents sudden color shifts during scrolling
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // Global Typography
      textTheme: GoogleFonts.interTextTheme(
          scheme.brightness == Brightness.dark
              ? ThemeData.dark().textTheme
              : ThemeData.light().textTheme
      ).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: roundedBorder,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0, // Flat design with solid fills
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          shape: roundedBorder,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 2,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // Input Decoration (Text fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.light ? _slate100 : _slate800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cornerRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cornerRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cornerRadius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
      ),

      // Cards with clean borders instead of heavy shadows
      cardTheme: CardThemeData(
        color: scheme.brightness == Brightness.light ? Colors.white : _slate800,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cornerRadius),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        shape: roundedBorder,
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minLeadingWidth: 0,
      ),

      // Material 3 Floating Navigation Bar support
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.brightness == Brightness.light ? Colors.white : _slate800,
        indicatorColor: scheme.primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.brightness == Brightness.light ? _slate800 : _slate100,
        contentTextStyle: TextStyle(color: scheme.brightness == Brightness.light ? Colors.white : _slate900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        shape: roundedBorder,
        backgroundColor: scheme.brightness == Brightness.light ? Colors.white : _slate800,
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _primaryTeal,
      brightness: Brightness.light,
    );

    // Inject custom structural light mode values
    final refinedScheme = baseScheme.copyWith(
      surface: _slate50,             // Screen canvas
      surfaceContainer: Colors.white, // Containers & Cards
      onSurface: _slate900,           // Dark primary text
      onSurfaceVariant: const Color(0xFF64748B), // Slate 500 secondary text
      outlineVariant: _slate100,      // Thin line separators
    );

    return _baseTheme(refinedScheme);
  }

  static ThemeData get darkTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: _primaryTeal,
      brightness: Brightness.dark,
    );

    // Inject custom structural dark mode values
    final refinedScheme = baseScheme.copyWith(
      surface: _slate900,             // Dark deep canvas
      surfaceContainer: _slate800,    // Elevated cards
      onSurface: _slate50,            // Light primary text
      onSurfaceVariant: const Color(0xFF94A3B8), // Slate 400 secondary text
      outlineVariant: const Color(0xFF334155),   // Slate 700 dark lines
    );

    return _baseTheme(refinedScheme);
  }

  // Helper to create a premium success SnackBar
  static SnackBar successSnackBar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3), SnackBarAction? action}) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF10B981), // Emerald 500
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: action,
    );
  }

  // Helper to create a premium error SnackBar
  static SnackBar errorSnackBar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 4), SnackBarAction? action}) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF43F5E), // Rose 500
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: action,
    );
  }
}