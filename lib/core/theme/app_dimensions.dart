import 'package:flutter/material.dart';

class AppDimensions {
  // Spacing System - Material Design 3 based
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  
  // Padding presets
  static const double paddingTiny = spacing4;
  static const double paddingSmall = spacing8;
  static const double paddingMedium = spacing16;
  static const double paddingLarge = spacing24;
  static const double paddingXLarge = spacing32;
  
  // Margin presets
  static const double marginTiny = spacing4;
  static const double marginSmall = spacing8;
  static const double marginMedium = spacing16;
  static const double marginLarge = spacing24;
  static const double marginXLarge = spacing32;
  
  // Border radius
  static const double radiusNone = 0.0;
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 20.0;
  static const double radiusRound = 50.0;
  
  // Elevation levels
  static const double elevationNone = 0.0;
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationLarge = 6.0;
  static const double elevationHigh = 8.0;
  static const double elevationVeryHigh = 12.0;
  
  // Icon sizes
  static const double iconTiny = 16.0;
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconXXLarge = 64.0;
  
  // Button dimensions
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double buttonHeightXLarge = 56.0;
  
  static const double buttonMinWidth = 64.0;
  static const double buttonMaxWidth = 320.0;
  
  // Input field dimensions
  static const double inputHeightSmall = 32.0;
  static const double inputHeightMedium = 40.0;
  static const double inputHeightLarge = 48.0;
  static const double inputHeightMultiline = 80.0;
  
  // Card dimensions
  static const double cardMinHeight = 80.0;
  static const double cardMaxWidth = 400.0;
  static const double cardAspectRatio = 16 / 9;
  
  // IoT specific dimensions
  static const double sensorCardHeight = 120.0;
  static const double sensorCardWidth = 160.0;
  static const double chartMinHeight = 200.0;
  static const double chartMaxHeight = 400.0;
  
  // Device card dimensions
  static const double deviceCardHeight = 140.0;
  static const double deviceCardMinWidth = 280.0;
  static const double deviceCardMaxWidth = 360.0;
  
  // Navigation dimensions
  static const double navigationBarHeight = 60.0;
  static const double tabBarHeight = 48.0;
  static const double appBarHeight = 56.0;
  static const double extendedAppBarHeight = 112.0;
  
  // Divider and border widths
  static const double dividerThickness = 1.0;
  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;
  static const double borderThick = 4.0;
  
  // Touch target sizes (accessibility)
  static const double minTouchTarget = 44.0;
  static const double recommendedTouchTarget = 48.0;
  
  // Screen breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  // Container constraints
  static const double maxContentWidth = 1200.0;
  static const double sideMarginMobile = spacing16;
  static const double sideMarginTablet = spacing24;
  static const double sideMarginDesktop = spacing32;
  
  // Animation durations (in milliseconds)
  static const int animationFast = 150;
  static const int animationMedium = 300;
  static const int animationSlow = 500;
  static const int animationVerySlow = 1000;
  
  // Helper methods for responsive design
  static double getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return sideMarginMobile;
    if (width < tabletBreakpoint) return sideMarginTablet;
    return sideMarginDesktop;
  }
  
  static double getResponsiveCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = getResponsivePadding(context);
    final maxWidth = width - (padding * 2);
    
    if (width < mobileBreakpoint) {
      return maxWidth;
    } else if (width < tabletBreakpoint) {
      return maxWidth > deviceCardMaxWidth * 2 
        ? (maxWidth - paddingMedium) / 2 
        : maxWidth;
    } else {
      final columns = (maxWidth / (deviceCardMaxWidth + paddingMedium)).floor();
      return (maxWidth - (paddingMedium * (columns - 1))) / columns;
    }
  }
  
  static int getResponsiveColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 1;
    if (width < tabletBreakpoint) return 2;
    return ((width - getResponsivePadding(context) * 2) / (deviceCardMaxWidth + paddingMedium)).floor();
  }
  
  // Edge insets presets
  static const EdgeInsets paddingAllTiny = EdgeInsets.all(paddingTiny);
  static const EdgeInsets paddingAllSmall = EdgeInsets.all(paddingSmall);
  static const EdgeInsets paddingAllMedium = EdgeInsets.all(paddingMedium);
  static const EdgeInsets paddingAllLarge = EdgeInsets.all(paddingLarge);
  static const EdgeInsets paddingAllXLarge = EdgeInsets.all(paddingXLarge);
  
  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: paddingSmall);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: paddingMedium);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: paddingLarge);
  
  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(vertical: paddingSmall);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(vertical: paddingMedium);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(vertical: paddingLarge);
  
  static const EdgeInsets marginAllSmall = EdgeInsets.all(marginSmall);
  static const EdgeInsets marginAllMedium = EdgeInsets.all(marginMedium);
  static const EdgeInsets marginAllLarge = EdgeInsets.all(marginLarge);
  
  // Border radius presets
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(Radius.circular(radiusXLarge));
  
  // Custom border radius for specific components
  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius buttonBorderRadius = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius inputBorderRadius = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius chipBorderRadius = BorderRadius.all(Radius.circular(radiusRound));
}
