import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';
import '../services/TextToSpeech.dart';

/// Accessibility helper class for visually impaired users
class AccessibilityHelper {
  
  /// Creates a high-contrast, large-touch button
  static Widget createAccessibleButton({
    required String text,
    required VoidCallback onPressed,
    String? semanticLabel,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    bool isLarge = true,
  }) {
    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: isLarge ? AppDimensions.recommendedTouchTarget : AppDimensions.minTouchTarget,
          minWidth: AppDimensions.buttonMinWidth,
        ),
        child: ElevatedButton(
          onPressed: () async {
            // Haptic feedback for better accessibility
            HapticFeedback.lightImpact();
            
            // Announce button press
            await TextToSpeech.speak('$text button pressed');
            
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: textColor ?? AppColors.onPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.paddingMedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            elevation: AppDimensions.elevationMedium,
            textStyle: isLarge 
                ? AppTextStyles.buttonTextLarge
                : AppTextStyles.buttonTextMedium,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isLarge ? AppDimensions.iconLarge : AppDimensions.iconMedium,
                ),
                SizedBox(width: AppDimensions.spacing8),
              ],
              Text(text),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates an accessible card with proper semantics and haptic feedback
  static Widget createAccessibleCard({
    required Widget child,
    required String semanticLabel,
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    String? tapHint,
    String? doubleTapHint,
    Color? backgroundColor,
    Color? borderColor,
    bool isHighContrast = true,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: tapHint ?? (onTap != null ? 'Tap to activate' : null),
      child: GestureDetector(
        onTap: onTap != null ? () async {
          HapticFeedback.selectionClick();
          if (tapHint != null) {
            await TextToSpeech.speak(tapHint);
          }
          onTap();
        } : null,
        onDoubleTap: onDoubleTap != null ? () async {
          HapticFeedback.mediumImpact();
          if (doubleTapHint != null) {
            await TextToSpeech.speak(doubleTapHint);
          }
          onDoubleTap();
        } : null,
        child: Container(
          constraints: BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: borderColor ?? (isHighContrast ? AppColors.outline : AppColors.outlineVariant),
              width: isHighContrast ? AppDimensions.borderMedium : AppDimensions.borderThin,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: AppDimensions.elevationMedium,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: child,
        ),
      ),
    );
  }

  /// Creates accessible text with high contrast
  static Widget createAccessibleText({
    required String text,
    TextStyle? style,
    bool isHeading = false,
    bool isImportant = false,
    Color? color,
    String? semanticLabel,
  }) {
    TextStyle finalStyle = style ?? AppTextStyles.textTheme.bodyLarge!;
    
    if (isHeading) {
      finalStyle = AppTextStyles.textTheme.titleLarge!;
    }
    
    if (isImportant) {
      finalStyle = finalStyle.copyWith(fontWeight: FontWeight.bold);
    }
    
    finalStyle = finalStyle.copyWith(
      color: color ?? AppColors.onSurface,
    );

    return Semantics(
      label: semanticLabel ?? text,
      header: isHeading,
      child: Text(
        text,
        style: finalStyle,
      ),
    );
  }

  /// Creates an accessible icon with proper semantics
  static Widget createAccessibleIcon({
    required IconData icon,
    required String semanticLabel,
    Color? color,
    double? size,
    VoidCallback? onTap,
  }) {
    final iconWidget = Icon(
      icon,
      color: color ?? AppColors.primary,
      size: size ?? AppDimensions.iconLarge,
    );

    if (onTap != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            await TextToSpeech.speak(semanticLabel);
            onTap();
          },
          child: Container(
            constraints: BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: iconWidget,
          ),
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: iconWidget,
    );
  }

  /// Announces a message via TTS and shows a high-contrast snackbar
  static void announceWithFeedback(
    BuildContext context, 
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) async {
    // Announce via TTS
    await TextToSpeech.speak(message);

    // Show visual feedback
    Color backgroundColor;
    Color textColor;
    
    if (isError) {
      backgroundColor = AppColors.error;
      textColor = AppColors.onError;
    } else if (isSuccess) {
      backgroundColor = AppColors.success;
      textColor = AppColors.onSuccess;
    } else {
      backgroundColor = AppColors.primary;
      textColor = AppColors.onPrimary;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.textTheme.bodyLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),
    );

    // Haptic feedback
    if (isError) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Creates a progress indicator with accessibility announcements
  static Widget createAccessibleProgress({
    required double progress,
    required String label,
    String? semanticLabel,
  }) {
    final progressPercent = (progress * 100).round();
    
    return Semantics(
      label: semanticLabel ?? '$label: $progressPercent percent',
      value: progressPercent.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          createAccessibleText(
            text: label,
            isImportant: true,
          ),
          SizedBox(height: AppDimensions.spacing8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              color: AppColors.surfaceVariant,
              border: Border.all(
                color: AppColors.outline,
                width: AppDimensions.borderThin,
              ),
            ),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: AppDimensions.spacing4),
          createAccessibleText(
            text: '$progressPercent%',
            style: AppTextStyles.textTheme.bodyMedium,
            isImportant: true,
          ),
        ],
      ),
    );
  }
}
