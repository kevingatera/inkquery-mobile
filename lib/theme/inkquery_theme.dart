import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InkqueryTheme {
  static const Color _paper = Color(0xFFF4E9D8);
  static const Color _ink = Color(0xFF101A1C);
  static const Color _moss = Color(0xFF214E55);
  static const Color _gold = Color(0xFFDB9F48);
  static const Color _ember = Color(0xFFB35333);

  static ThemeData get theme {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _moss,
      onPrimary: Colors.white,
      secondary: _gold,
      onSecondary: _ink,
      error: _ember,
      onError: Colors.white,
      surface: const Color(0xFFF9F5EC),
      onSurface: _ink,
      surfaceContainerHighest: const Color(0xFFE7E1D1),
      onSurfaceVariant: const Color(0xFF425557),
      outline: const Color(0xFF8EA19D),
      outlineVariant: const Color(0xFFD7DED9),
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: _ink,
      onInverseSurface: _paper,
      inversePrimary: const Color(0xFF8FC3C9),
      tertiary: _ember,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFF2D5C7),
      onTertiaryContainer: _ink,
      primaryContainer: const Color(0xFFD2E5E6),
      onPrimaryContainer: _ink,
      secondaryContainer: const Color(0xFFF3E1BD),
      onSecondaryContainer: _ink,
      errorContainer: const Color(0xFFF7D7CF),
      onErrorContainer: _ink,
      surfaceDim: const Color(0xFFE6DECF),
      surfaceBright: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF7F2E9),
      surfaceContainer: const Color(0xFFF1EADF),
      surfaceContainerHigh: const Color(0xFFECE4D6),
    );

    final textTheme = GoogleFonts.dmSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _ink,
        letterSpacing: -1.2,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
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
        height: 1.45,
        color: _ink,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        height: 1.45,
        color: _ink,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        height: 1.35,
        color: const Color(0xFF516366),
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _ink,
      ),
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: _paper,
      textTheme: textTheme,
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.78),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge!,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
    );
  }

  static const backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF9F2E7),
        Color(0xFFE8F0EE),
        Color(0xFFF5E6D3),
      ],
      stops: [0, 0.55, 1],
    ),
  );

  static BoxDecoration glassPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
