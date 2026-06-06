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
  // Central seed color used across light and dark themes
  static const Color _seedColor = Color(0xFF3B82F6); // indigo-ish blue

  static ThemeData _baseTheme(ColorScheme scheme, Brightness brightness) {
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface, // scaffold background should use surface in latest Material
      primaryColor: scheme.primary,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        toolbarHeight: 56,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // use surfaceContainerHighest for container background in newer API
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: scheme.primary)),
        hintStyle: TextStyle(color: scheme.onSurface.withAlpha((0.6 * 255).round())),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 1,
        shape: rounded,
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // List tiles
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurface.withAlpha((0.6 * 255).round()),
        showUnselectedLabels: true,
        elevation: 4,
      ),

      // Material 3 NavigationBar (NavigationRail / NavigationBar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withAlpha((0.12 * 255).round()),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          return TextStyle(color: scheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          // keep selection logic; use withAlpha for opacity
          // Warning: MaterialStateProperty is deprecated in some SDKs but still works
          // for compatibility here.
          // Use WidgetStateProperty if migrating to newest APIs.
          // selected state color
          // Note: can't reference WidgetState here to maintain compatibility.
          return IconThemeData(color: scheme.onSurface.withAlpha((0.7 * 255).round()));
        }),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: scheme.outline.withAlpha((0.6 * 255).round()), thickness: 1),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(shape: rounded, backgroundColor: scheme.surface),

      // Card and surface behaviors
      //surfaceTintColor: scheme.primary,
    );
  }


  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light);
    return _baseTheme(scheme, Brightness.light);
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark);
    return _baseTheme(scheme, Brightness.dark).copyWith(
      textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme)
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    );
  }

  // Helper to create a green success SnackBar
  static SnackBar successSnackBar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3), SnackBarAction? action}) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: textStyle)),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: action,
    );
  }

  // Helper to create a red error SnackBar
  static SnackBar errorSnackBar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 4), SnackBarAction? action}) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: textStyle)),
        ],
      ),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      action: action,
    );
  }
}
