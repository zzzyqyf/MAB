import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';

/// Configuration class for accessibility settings
class AccessibilityConfig {
  
  // High contrast mode settings
  static const bool useHighContrast = true;
  static const bool useLargerText = true;
  static const bool useHapticFeedback = true;
  static const bool useTTS = true;
  
  // Enhanced touch targets for visually impaired users
  static const double minTouchTargetSize = 60.0;
  static const double preferredTouchTargetSize = 68.0;
  
  // Text scaling factors for accessibility
  static const double textScaleFactor = 1.2;
  static const double largeTextScaleFactor = 1.5;
  
  // High contrast color palette
  static const Map<String, Color> highContrastColors = {
    'primary': Color(0xFF000080),
    'onPrimary': Color(0xFFFFFFFF),
    'secondary': Color(0xFF006666),
    'onSecondary': Color(0xFFFFFFFF),
    'surface': Color(0xFFFFFFFF),
    'onSurface': Color(0xFF000000),
    'background': Color(0xFFFFFFFF),
    'onBackground': Color(0xFF000000),
    'error': Color(0xFFCC0000),
    'onError': Color(0xFFFFFFFF),
    'success': Color(0xFF006600),
    'onSuccess': Color(0xFFFFFFFF),
    'warning': Color(0xFFFF8800),
    'onWarning': Color(0xFFFFFFFF),
  };
  
  // Spacing multipliers for accessibility
  static const double spacingMultiplier = 1.3;
  static const double paddingMultiplier = 1.4;
  
  // Animation duration settings (slower for accessibility)
  static const Duration shortAnimationDuration = Duration(milliseconds: 400);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 600);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  /// Get accessible text style with proper scaling
  static TextStyle getAccessibleTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 16) * textScaleFactor,
      fontWeight: FontWeight.w600, // Make text bolder for better visibility
      height: 1.5, // Increased line height for better readability
    );
  }
  
  /// Get high contrast color for a given color name
  static Color getHighContrastColor(String colorName) {
    return highContrastColors[colorName] ?? AppColors.primary;
  }
  
  /// Get accessible dimensions with proper scaling
  static double getAccessibleDimension(double baseDimension) {
    return baseDimension * spacingMultiplier;
  }
  
  /// Get accessible padding with proper scaling
  static EdgeInsets getAccessiblePadding(EdgeInsets basePadding) {
    return basePadding * paddingMultiplier;
  }
  
  /// Create accessible button style
  static ButtonStyle getAccessibleButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    bool isLarge = false,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? getHighContrastColor('primary'),
      foregroundColor: foregroundColor ?? getHighContrastColor('onPrimary'),
      minimumSize: Size(
        minTouchTargetSize,
        isLarge ? preferredTouchTargetSize : minTouchTargetSize,
      ),
      padding: getAccessiblePadding(
        EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLarge,
          vertical: AppDimensions.paddingMedium,
        ),
      ),
      textStyle: getAccessibleTextStyle(
        isLarge ? AppTextStyles.buttonTextLarge : AppTextStyles.buttonTextMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        side: BorderSide(
          color: getHighContrastColor('onSurface'),
          width: AppDimensions.borderMedium,
        ),
      ),
      elevation: AppDimensions.elevationMedium,
    );
  }
  
  /// Create accessible card decoration
  static BoxDecoration getAccessibleCardDecoration({
    Color? backgroundColor,
    Color? borderColor,
    bool isHighlighted = false,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? getHighContrastColor('surface'),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      border: Border.all(
        color: borderColor ?? getHighContrastColor('onSurface'),
        width: isHighlighted ? AppDimensions.borderThick : AppDimensions.borderMedium,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: AppDimensions.elevationMedium,
          offset: const Offset(0, 2),
          spreadRadius: 1,
        ),
      ],
    );
  }
  
  /// Semantic labels for common UI elements
  static const Map<String, String> semanticLabels = {
    'back': 'Go back to previous screen',
    'menu': 'Open navigation menu',
    'close': 'Close current view',
    'add': 'Add new item',
    'edit': 'Edit current item',
    'delete': 'Delete current item',
    'save': 'Save changes',
    'cancel': 'Cancel action',
    'refresh': 'Refresh content',
    'search': 'Search for items',
    'filter': 'Filter results',
    'settings': 'Open settings',
    'profile': 'View profile',
    'notifications': 'View notifications',
    'device_online': 'Device is online and connected',
    'device_offline': 'Device is offline or disconnected',
    'device_connecting': 'Device is connecting',
    'sensor_reading': 'Current sensor reading',
    'status_good': 'Status is good',
    'status_warning': 'Status has warnings',
    'status_error': 'Status has errors',
  };
  
  /// Get semantic label for common actions
  static String getSemanticLabel(String key) {
    return semanticLabels[key] ?? key;
  }
  
  /// TTS announcement templates
  static const Map<String, String> announcementTemplates = {
    'device_status': 'Device {name} is {status}',
    'sensor_update': '{sensor} reading is {value} {unit}',
    'navigation': 'Navigated to {page}',
    'action_complete': '{action} completed successfully',
    'error': 'Error: {message}',
    'loading': 'Loading {content}',
    'page_loaded': '{page} page loaded. {content}',
  };
  
  /// Get formatted announcement
  static String getAnnouncement(String template, Map<String, String> variables) {
    String announcement = announcementTemplates[template] ?? template;
    
    variables.forEach((key, value) {
      announcement = announcement.replaceAll('{$key}', value);
    });
    
    return announcement;
  }
  
  /// Accessibility guidelines compliance checker
  static bool meetsAccessibilityGuidelines({
    required Color background,
    required Color foreground,
    required double fontSize,
    required double touchTargetSize,
  }) {
    // Check contrast ratio (WCAG AA requires 4.5:1, AAA requires 7:1)
    final contrastRatio = _calculateContrastRatio(background, foreground);
    final meetsContrast = contrastRatio >= 7.0; // AAA standard
    
    // Check font size (minimum 16px for body text)
    final meetsFontSize = fontSize >= 16.0;
    
    // Check touch target size (minimum 44px, recommended 48px)
    final meetsTouchTarget = touchTargetSize >= 56.0; // Our enhanced requirement
    
    return meetsContrast && meetsFontSize && meetsTouchTarget;
  }
  
  /// Calculate contrast ratio between two colors
  static double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
