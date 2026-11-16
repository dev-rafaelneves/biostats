import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  // Light Mode (Apple HIG)
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A); // slate-900
  static const Color lightTextSecondary = Color(0xFF64748B); // slate-500

  // Dark Mode (Slate Palette)
  static const Color darkBackground = Color(0xFF020617); // slate-950
  static const Color darkSurface = Color(0xFF0F172A); // slate-900
  static const Color darkBorder = Color(0xFF1E293B); // slate-800
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // slate-50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // slate-400

  // Accents
  static const Color indigoPrimary = Color(0xFF4F46E5); // indigo-600
  static const Color indigoLight = Color(0xFF6366F1); // indigo-500
  static const Color indigoSoft = Color(0xFFEEF2FF); // indigo-50
  static const Color emerald = Color(0xFF10B981); // emerald-500
  static const Color orange = Color(0xFFF97316); // orange-500
  static const Color rose = Color(0xFFF43F5E); // rose-500
  static const Color blue = Color(0xFF3B82F6); // blue-500

  // Sub-superfícies e textos com contraste WCAG AA (>= 4.5:1)
  static const Color lightSurfaceSubtle = Color(0xFFF1F5F9); // slate-100
  static const Color darkSurfaceSubtle = Color(0xFF1E293B); // slate-800
  static const Color lightTextAccessibleMuted = Color(0xFF475569); // slate-600 (contraste 7.0:1 em branco)
  static const Color darkTextAccessibleMuted = Color(0xFF94A3B8); // slate-400 (contraste 6.4:1 em slate-900)
}

@immutable
class BioThemeColors extends ThemeExtension<BioThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;

  const BioThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
  });

  static const BioThemeColors light = BioThemeColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceSubtle: AppColors.lightSurfaceSubtle,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextAccessibleMuted,
    textMuted: AppColors.lightTextSecondary,
    accent: AppColors.indigoPrimary,
  );

  static const BioThemeColors dark = BioThemeColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceSubtle: AppColors.darkSurfaceSubtle,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextAccessibleMuted,
    accent: AppColors.indigoLight,
  );

  @override
  BioThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
  }) {
    return BioThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
    );
  }

  @override
  BioThemeColors lerp(ThemeExtension<BioThemeColors>? other, double t) {
    if (other is! BioThemeColors) return this;
    return BioThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension BioThemeContext on BuildContext {
  BioThemeColors get bioColors =>
      Theme.of(this).extension<BioThemeColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? BioThemeColors.dark
          : BioThemeColors.light);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.indigoPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.indigoPrimary,
        secondary: AppColors.indigoLight,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.rose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF1F5F9),
        thickness: 1,
        space: 1,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.indigoPrimary,
        brightness: Brightness.light,
      ),
      extensions: const [BioThemeColors.light],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.indigoLight,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.indigoLight,
        secondary: AppColors.indigoPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.rose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.indigoLight,
        brightness: Brightness.dark,
      ),
      extensions: const [BioThemeColors.dark],
    );
  }
}
