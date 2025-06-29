import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Base font family
  static const String fontFamily = 'Roboto';
  
  // Text Themes based on Material Design 3 - Enhanced for Accessibility
  static const TextTheme textTheme = TextTheme(
    // Display styles - Larger for accessibility
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 72, // Increased from 57
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 56, // Increased from 45
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 44, // Increased from 36
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.22,
    ),
    
    // Headline styles - Larger and bolder
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 40, // Increased from 32
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 34, // Increased from 28
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28, // Increased from 24
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.33,
    ),
    
    // Title styles - Much larger
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 26, // Increased from 22
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20, // Increased from 16
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18, // Increased from 14
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    
    // Body styles - Larger for better readability
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20, // Increased from 16
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18, // Increased from 14
      fontWeight: FontWeight.w500,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16, // Increased from 12
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
      height: 1.33,
    ),
    
    // Label styles - Larger for accessibility
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18, // Increased from 14
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16, // Increased from 12
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14, // Increased from 11
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );
  
  // Custom app-specific text styles - Enhanced for accessibility
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24, // Increased from 20
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.4,
  );
  
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22, // Increased from 18
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.33,
  );
  
  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18, // Increased from 14
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.onSurfaceVariant,
  );
  
  static const TextStyle dataValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28, // Increased from 24
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.17,
  );
  
  static const TextStyle dataUnit = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18, // Increased from 14
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.onSurfaceVariant,
  );
  
  static const TextStyle buttonTextLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20, // Increased from 16
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.25,
  );
  
  static const TextStyle buttonTextMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18, // Increased from 14
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle chipText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16, // Increased from 12
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.33,
  );
  
  static const TextStyle statusText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16, // Increased from 12
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.33,
  );
  
  static const TextStyle timestampText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14, // Increased from 11
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: AppColors.onSurfaceVariant,
  );
  
  // IoT specific text styles - Enhanced for accessibility
  static const TextStyle sensorValue = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32, // Increased from 28
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.14,
  );
  
  static const TextStyle sensorLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.onSurfaceVariant,
  );
  
  static const TextStyle deviceName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.50,
  );
  
  static const TextStyle deviceStatus = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  // Error and validation text styles
  static const TextStyle errorText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.error,
  );
  
  static const TextStyle successText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.success,
  );
  
  static const TextStyle warningText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.warning,
  );
  
  // Accessibility helpers
  static TextStyle ensureContrast(TextStyle style, Color backgroundColor) {
    final textColor = style.color ?? AppColors.onSurface;
    if (!AppColors.meetsWCAGAA(backgroundColor, textColor)) {
      // Use high contrast alternative
      return style.copyWith(
        color: backgroundColor.computeLuminance() > 0.5 
          ? AppColors.onSurface 
          : AppColors.surface,
      );
    }
    return style;
  }
}
