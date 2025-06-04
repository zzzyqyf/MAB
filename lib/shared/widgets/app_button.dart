import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonType { primary, secondary, outlined, text }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? semanticLabel;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = _getButtonHeight();
    final buttonPadding = _getButtonPadding();
    final textStyle = _getTextStyle();

    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: AppDimensions.iconSmall,
            height: AppDimensions.iconSmall,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? _getDefaultForegroundColor(),
              ),
            ),
          ),
          SizedBox(width: AppDimensions.spacing8),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: _getIconSize(),
            color: foregroundColor ?? _getDefaultForegroundColor(),
          ),
          SizedBox(width: AppDimensions.spacing8),
        ],
        Text(
          text,
          style: textStyle.copyWith(
            color: foregroundColor ?? _getDefaultForegroundColor(),
          ),
        ),
      ],
    );    Widget button;
    switch (type) {
      case AppButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: foregroundColor ?? AppColors.onPrimary,
            minimumSize: Size(
              isFullWidth ? double.infinity : AppDimensions.buttonMinWidth,
              buttonHeight,
            ),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.buttonBorderRadius,
            ),
            elevation: AppDimensions.elevationSmall,
          ),
          child: buttonChild,
        );
        break;
      case AppButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.secondary,
            foregroundColor: foregroundColor ?? AppColors.onSecondary,
            minimumSize: Size(
              isFullWidth ? double.infinity : AppDimensions.buttonMinWidth,
              buttonHeight,
            ),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.buttonBorderRadius,
            ),
            elevation: AppDimensions.elevationSmall,
          ),
          child: buttonChild,
        );
        break;
      case AppButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            backgroundColor: backgroundColor,
            minimumSize: Size(
              isFullWidth ? double.infinity : AppDimensions.buttonMinWidth,
              buttonHeight,
            ),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.buttonBorderRadius,
            ),
            side: BorderSide(
              color: foregroundColor ?? AppColors.primary,
              width: AppDimensions.borderThin,
            ),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? AppColors.primary,
            backgroundColor: backgroundColor,
            minimumSize: Size(
              isFullWidth ? double.infinity : AppDimensions.buttonMinWidth,
              buttonHeight,
            ),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.buttonBorderRadius,
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        child: button,
      );
    }

    return button;
  }
  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppDimensions.buttonHeightSmall;
      case AppButtonSize.medium:
        return AppDimensions.buttonHeightMedium;
      case AppButtonSize.large:
        return AppDimensions.buttonHeightLarge;
    }
  }

  EdgeInsetsGeometry _getButtonPadding() {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        );
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLarge,
          vertical: AppDimensions.paddingMedium,
        );
      case AppButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingXLarge,
          vertical: AppDimensions.paddingLarge,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.textTheme.labelMedium!;
      case AppButtonSize.medium:
        return AppTextStyles.buttonTextMedium;
      case AppButtonSize.large:
        return AppTextStyles.buttonTextLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppDimensions.iconSmall;
      case AppButtonSize.medium:
        return AppDimensions.iconMedium;
      case AppButtonSize.large:
        return AppDimensions.iconLarge;
    }
  }

  Color _getDefaultForegroundColor() {
    switch (type) {
      case AppButtonType.primary:
        return AppColors.onPrimary;
      case AppButtonType.secondary:
        return AppColors.onSecondary;
      case AppButtonType.outlined:
        return AppColors.primary;
      case AppButtonType.text:
        return AppColors.primary;
    }
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double? size;
  final bool isLoading;
  final String? semanticLabel;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size,
    this.isLoading = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: AppDimensions.iconSmall,
              height: AppDimensions.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.primary,
                ),
              ),
            )
          : Icon(
              icon,
              color: color ?? AppColors.primary,
              size: size ?? AppDimensions.iconMedium,
            ),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: Size(
          AppDimensions.minTouchTarget,
          AppDimensions.minTouchTarget,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
      ),
      tooltip: tooltip,
    );

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        child: button,
      );
    }

    return button;
  }
}

class AppFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? heroTag;
  final bool isExtended;
  final String? label;
  final bool isLoading;
  final String? semanticLabel;

  const AppFloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.heroTag,
    this.isExtended = false,
    this.label,
    this.isLoading = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget fabChild = isLoading
        ? SizedBox(
            width: AppDimensions.iconMedium,
            height: AppDimensions.iconMedium,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
            ),
          )
        : Icon(icon, size: AppDimensions.iconMedium);

    Widget fab = isExtended && label != null
        ? FloatingActionButton.extended(
            onPressed: isLoading ? null : onPressed,
            icon: fabChild,
            label: Text(
              label!,
              style: AppTextStyles.buttonTextMedium.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: AppDimensions.elevationMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            ),
            heroTag: heroTag,
            tooltip: tooltip,
          )
        : FloatingActionButton(
            onPressed: isLoading ? null : onPressed,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: AppDimensions.elevationMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            ),
            heroTag: heroTag,
            tooltip: tooltip,
            child: fabChild,
          );

    if (semanticLabel != null) {
      fab = Semantics(
        label: semanticLabel,
        child: fab,
      );
    }

    return fab;
  }
}
