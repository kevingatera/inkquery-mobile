import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InkqueryTheme {
  static const Color paper = Color(0xFFF6F1E7);
  static const Color _ink = Color(0xFF1E1A16);
  static const Color _moss = Color(0xFF2C5A52);
  static const Color _gold = Color(0xFFC48C3C);
  static const Color _ember = Color(0xFF9F4D33);
  static const Color _line = Color(0xFFD9D1C3);
  static const Color _panel = Color(0xFFFFFCF7);
  static const Color _muted = Color(0xFF655B53);

  static ThemeData get theme {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _moss,
      onPrimary: Colors.white,
      secondary: _gold,
      onSecondary: _ink,
      error: _ember,
      onError: Colors.white,
      surface: _panel,
      onSurface: _ink,
      surfaceContainerHighest: const Color(0xFFECE4D8),
      onSurfaceVariant: _muted,
      outline: const Color(0xFF9B9386),
      outlineVariant: _line,
      shadow: Colors.black12,
      scrim: Colors.black54,
      inverseSurface: _ink,
      onInverseSurface: paper,
      inversePrimary: const Color(0xFF8FC3C9),
      tertiary: _ember,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFF0D7CC),
      onTertiaryContainer: _ink,
      primaryContainer: const Color(0xFFD2E5E6),
      onPrimaryContainer: _ink,
      secondaryContainer: const Color(0xFFF3E1BD),
      onSecondaryContainer: _ink,
      errorContainer: const Color(0xFFF7D7CF),
      onErrorContainer: _ink,
      surfaceDim: const Color(0xFFE6DDCF),
      surfaceBright: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF7F2E9),
      surfaceContainer: const Color(0xFFF1EADF),
      surfaceContainerHigh: const Color(0xFFECE4D6),
    );

    final textTheme = GoogleFonts.dmSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: _ink,
        letterSpacing: -0.8,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _ink,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        height: 1.4,
        color: _ink,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        height: 1.4,
        color: _ink,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        height: 1.35,
        color: _muted,
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _ink,
      ),
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      textTheme: textTheme,
      useMaterial3: true,
      dividerColor: _line,
      appBarTheme: AppBarTheme(
        backgroundColor: _panel,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: _panel,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: _line),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge!,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _panel,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: _line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  static const backgroundDecoration = BoxDecoration(color: paper);

  static BoxDecoration panelDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: scheme.outlineVariant),
    );
  }
}
