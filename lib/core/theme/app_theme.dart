import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimensions.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightColorScheme,
      textTheme: AppTextStyles.textTheme,
      fontFamily: AppTextStyles.fontFamily,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: AppDimensions.elevationMedium,
        centerTitle: true,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: AppColors.onPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.onPrimary,
          size: AppDimensions.iconMedium,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.onPrimary,
          size: AppDimensions.iconMedium,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shadowColor: AppColors.shadow.withValues(alpha: 0.3),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppDimensions.elevationSmall,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        color: AppColors.surface,
        shadowColor: AppColors.shadow.withValues(alpha: 0.1),
        surfaceTintColor: AppColors.surfaceVariant,
        margin: AppDimensions.marginAllSmall,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: AppDimensions.elevationSmall,
          shadowColor: AppColors.shadow.withValues(alpha: 0.2),
          surfaceTintColor: AppColors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
            vertical: AppDimensions.paddingMedium,
          ),
          minimumSize: Size(AppDimensions.buttonMinWidth, AppDimensions.buttonHeightMedium),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.buttonBorderRadius,
          ),
          textStyle: AppTextStyles.buttonTextMedium,
        ),
      ),      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: AppColors.outline),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
            vertical: AppDimensions.paddingMedium,
          ),
          minimumSize: Size(AppDimensions.buttonMinWidth, AppDimensions.buttonHeightMedium),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.buttonBorderRadius,
          ),
          textStyle: AppTextStyles.buttonTextMedium,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          minimumSize: Size(AppDimensions.buttonMinWidth, AppDimensions.buttonHeightSmall),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.buttonBorderRadius,
          ),
          textStyle: AppTextStyles.buttonTextMedium,
        ),
      ),
      
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          padding: EdgeInsets.all(AppDimensions.paddingSmall),
          minimumSize: Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          iconSize: AppDimensions.iconMedium,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: AppDimensions.elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        ),
        iconSize: AppDimensions.iconMedium,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        elevation: AppDimensions.elevationMedium,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: AppTextStyles.textTheme.labelSmall?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(
          size: AppDimensions.iconMedium,
          color: AppColors.primary,
        ),
        unselectedIconTheme: IconThemeData(
          size: AppDimensions.iconMedium,
          color: AppColors.onSurfaceVariant,
        ),
      ),      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.primary, width: AppDimensions.borderMedium),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(color: AppColors.error, width: AppDimensions.borderMedium),
        ),
        contentPadding: AppDimensions.paddingAllMedium,
        hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        labelStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        errorStyle: AppTextStyles.errorText,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.secondary,
        labelStyle: AppTextStyles.chipText,
        secondaryLabelStyle: AppTextStyles.chipText.copyWith(
          color: AppColors.onPrimary,
        ),
        padding: AppDimensions.paddingAllSmall,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.chipBorderRadius,
        ),
        elevation: AppDimensions.elevationNone,
        pressElevation: AppDimensions.elevationSmall,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        elevation: AppDimensions.elevationHigh,
        titleTextStyle: AppTextStyles.textTheme.headlineSmall?.copyWith(
          color: AppColors.onSurface,
        ),
        contentTextStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
        ),
        actionsPadding: AppDimensions.paddingAllMedium,
        insetPadding: AppDimensions.paddingAllLarge,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.onSurface,
        contentTextStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: AppColors.surface,
        ),
        actionTextColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        elevation: AppDimensions.elevationMedium,
        behavior: SnackBarBehavior.floating,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: AppDimensions.paddingHorizontalMedium,
        minVerticalPadding: AppDimensions.paddingSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        titleTextStyle: AppTextStyles.textTheme.titleMedium,
        subtitleTextStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: AppTextStyles.textTheme.labelMedium,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.outline,
        thickness: AppDimensions.dividerThickness,
        space: AppDimensions.spacing16,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onPrimary;
          }
          return AppColors.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surfaceVariant;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surface;
        }),
        checkColor: WidgetStateProperty.all(AppColors.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.outline;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceVariant,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.1),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle: AppTextStyles.textTheme.labelMedium?.copyWith(
          color: AppColors.onPrimary,
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceVariant,
        circularTrackColor: AppColors.surfaceVariant,
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: AppTextStyles.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.textTheme.titleSmall,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: AppDimensions.borderMedium,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,
      
      // Visual density for touch interfaces
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Splash factory for ripple effects
      splashFactory: InkRipple.splashFactory,
    );
  }
  
  // Dark theme (for future implementation)
  static ThemeData get darkTheme {
    // TODO: Implement dark theme
    return lightTheme;
  }
}
