import 'package:flutter/material.dart';

class AppColors {
  // High Contrast Color Palette for Accessibility - Designed for visually impaired users
  static const Color primary = Color(0xFF000080); // Dark navy blue for maximum contrast
  static const Color primaryVariant = Color(0xFF000066);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  // Secondary Color Palette - High contrast teal
  static const Color secondary = Color(0xFF006666);
  static const Color secondaryVariant = Color(0xFF004D4D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  // Surface Colors - High contrast
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  static const Color onSurface = Color(0xFF000000);
  static const Color onSurfaceVariant = Color(0xFF2D2D2D);
  
  // Background Colors - Pure white for maximum contrast
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF000000);
  
  // Error Colors - High contrast red
  static const Color error = Color(0xFFCC0000);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF800000);
  
  // Warning Colors - High contrast orange
  static const Color warning = Color(0xFFFF8800);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFFBF6600);
  
  // Success Colors - High contrast green
  static const Color success = Color(0xFF006600);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF003300);
  
  // Outline Colors - Higher contrast
  static const Color outline = Color(0xFF444444);
  static const Color outlineVariant = Color(0xFF888888);
  
  // Shadow and Overlay
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
    // IoT Specific Colors
  static const Color temperatureHot = Color(0xFFF44336);
  static const Color temperatureCold = Color(0xFF2196F3);
  static const Color temperature = Color(0xFFFF9800); // Default temperature color
  static const Color hot = Color(0xFFF44336); // Alias for temperatureHot
  static const Color cold = Color(0xFF2196F3); // Alias for temperatureCold
  static const Color humidity = Color(0xFF4CAF50);
  static const Color lightIntensity = Color(0xFFFFC107);
  static const Color waterLevel = Color(0xFF00BCD4);
  static const Color soilMoisture = Color(0xFF8BC34A);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryVariant],
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, surfaceVariant],
  );
  
  // Chart Colors
  static const List<Color> chartColors = [
    primary,
    secondary,
    success,
    warning,
    error,
    Color(0xFF9C27B0), // Purple
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
  ];
  
  // Status Colors
  static const Color online = success;
  static const Color offline = Color(0xFF9E9E9E);
  static const Color connecting = warning;
  static const Color errorStatus = error;
  
  // Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: Color(0xFFD3E3FD),
    onPrimaryContainer: Color(0xFF001849),
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: Color(0xFFB3E5FC),
    onSecondaryContainer: Color(0xFF001F24),
    tertiary: Color(0xFF7D5260),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD8E4),
    onTertiaryContainer: Color(0xFF31111D),
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceVariant: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: shadow,
    scrim: scrim,
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFA4C7FF),
    surfaceTint: primary,
  );
  
  // Accessibility helpers
  static bool meetsWCAGAA(Color background, Color foreground) {
    return _calculateContrast(background, foreground) >= 4.5;
  }
  
  static bool meetsWCAGAAA(Color background, Color foreground) {
    return _calculateContrast(background, foreground) >= 7.0;
  }
  
  static double _calculateContrast(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
