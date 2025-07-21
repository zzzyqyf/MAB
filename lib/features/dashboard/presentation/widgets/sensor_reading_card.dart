import 'package:flutter/material.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

// Shared imports
import '../../../../shared/services/TextToSpeech.dart';

class SensorReadingCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final String status;
  final Color statusColor;
  final VoidCallback? onDoubleTap;

  const SensorReadingCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.statusColor,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $value $unit, Status: $status. Double tap for details.',
      child: GestureDetector(
        onTap: () {
          // Single tap triggers TTS
          TextToSpeech.speak('$title: $value $unit, Status: $status');
        },
        onDoubleTap: onDoubleTap,
        child: Container(
          height: 110, // Increased height to prevent overflow
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSmall, // Reduced horizontal padding to give more space
            vertical: AppDimensions.paddingSmall, // Less vertical padding
          ),
          margin: EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // First row: Icon + Sensor Name
              Row(
                children: [
                  // Icon - compact and clean
                  Container(
                    width: 36,
                    height: 36,
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  
                  SizedBox(width: AppDimensions.spacing12),
                  
                  // Sensor name - full width available
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Second row: Value + Status Badge with optimized spacing
              Padding(
                padding: EdgeInsets.only(top: 4), // Small padding to prevent overflow
                child: Row(
                  children: [
                    // Empty space to push elements to the right
                    Spacer(),
                    
                    // Value with unit - right next to status badge
                    Text(
                      '$value$unit',
                      style: AppTextStyles.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // Reduced font size to prevent overflow
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Prevent text overflow
                    ),
                    
                    // Minimal space between value and status badge
                    SizedBox(width: 4), // Reduced spacing
                    
                    // Status badge - right next to value with constrained width
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8, // Reduced horizontal padding
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
