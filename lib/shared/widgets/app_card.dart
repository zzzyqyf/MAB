import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;  final BorderSide? borderSide;
  final bool showShadow;
  final String? semanticLabel;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onDoubleTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.borderSide,
    this.showShadow = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Card(
      color: backgroundColor ?? AppColors.surface,
      elevation: showShadow ? (elevation ?? AppDimensions.elevationSmall) : 0,
      margin: margin ?? AppDimensions.marginAllSmall,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppDimensions.cardBorderRadius,
        side: borderSide ?? BorderSide.none,
      ),
      child: Padding(
        padding: padding ?? AppDimensions.paddingAllMedium,
        child: child,
      ),
    );

    if (onTap != null || onDoubleTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        borderRadius: borderRadius ?? AppDimensions.cardBorderRadius,
        child: cardWidget,
      );
    }

    if (semanticLabel != null) {
      cardWidget = Semantics(
        label: semanticLabel,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final String? subtitle;
  final Widget? trailing;
  final bool isLoading;
  final String? semanticLabel;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.onTap,
    this.onDoubleTap,
    this.subtitle,
    this.trailing,
    this.isLoading = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveValueColor = valueColor ?? AppColors.onSurface;

    return AppCard(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      semanticLabel: semanticLabel ?? '$title: $value $unit',
      child: SizedBox(
        height: AppDimensions.sensorCardHeight,
        width: AppDimensions.sensorCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header row with icon and title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: AppDimensions.iconLarge,
                  color: effectiveIconColor,
                ),
                if (trailing != null) trailing!,
              ],
            ),
            
            // Title and subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.sensorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppDimensions.spacing4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.timestampText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            
            // Value and unit
            if (isLoading)
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveIconColor),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppTextStyles.sensorValue.copyWith(
                        color: effectiveValueColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacing4),
                  Text(
                    unit,
                    style: AppTextStyles.dataUnit,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final String deviceId;
  final String status;
  final DateTime? lastSeen;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? statusColor;
  final String? semanticLabel;

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.deviceId,
    required this.status,
    this.lastSeen,
    this.onTap,
    this.onLongPress,
    this.actions,
    this.leading,
    this.statusColor,
    this.semanticLabel,
  });

  Color get _statusColor {
    if (statusColor != null) return statusColor!;
    switch (status.toLowerCase()) {
      case 'online':
        return AppColors.online;
      case 'offline':
      default:
        return AppColors.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      semanticLabel: semanticLabel ?? 'Device $deviceName, status $status',
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: AppDimensions.cardBorderRadius,
        child: Padding(
          padding: AppDimensions.paddingAllMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: AppDimensions.spacing12),
                  ],
                  Expanded(                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deviceName,
                          style: AppTextStyles.deviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppDimensions.spacing4),
                        Text(
                          'ID: $deviceId',
                          style: AppTextStyles.cardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
              
              SizedBox(height: AppDimensions.spacing16),
              
              // Status and last seen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSmall,
                      vertical: AppDimensions.paddingTiny,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: AppDimensions.chipBorderRadius,
                      border: Border.all(
                        color: _statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: AppTextStyles.statusText.copyWith(
                        color: _statusColor,
                      ),
                    ),
                  ),
                  if (lastSeen != null)
                    Text(
                      _formatLastSeen(lastSeen!),
                      style: AppTextStyles.timestampText,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
