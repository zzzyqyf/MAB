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
    // Helper function to format title with line breaks at 15 characters max
    String formatTitle(String title) {
      if (title.length <= 15) {
        return title;
      }
      
      // Find the last space before or at position 15
      int breakPoint = -1;
      
      // Look for the last space within the first 15 characters
      for (int i = 14; i >= 0; i--) {
        if (title[i] == ' ') {
          breakPoint = i;
          break;
        }
      }
      
      // If no space found within 15 chars, force break at 15
      if (breakPoint == -1) {
        breakPoint = 15;
      }
      
      return title.substring(0, breakPoint) + '\n' + title.substring(breakPoint + 1);
    }

    return Semantics(
      label: '$title: $value $unit, Status: $status. Double tap for details.',
      child: GestureDetector(
        onTap: () {
          // Single tap triggers TTS
          TextToSpeech.speak('$title: $value $unit, Status: $status');
        },
        onDoubleTap: onDoubleTap,
        child: Container(
          height: 80,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSmall,
            vertical: AppDimensions.paddingSmall,
          ),
          margin: EdgeInsets.symmetric(vertical: AppDimensions.spacing4),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align everything to top
            children: [
              // Left side: Icon
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
              
              // Middle: Title (with word wrap support)
              Expanded(
                child: Text(
                  formatTitle(title),
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    height: 1.2, // Control line height for better spacing
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(width: AppDimensions.spacing8),
              
              // Right side: Value, Unit, and Status (aligned to top)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start, // Align to top
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Value with unit on first line
                  Text(
                    '$value$unit',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Status badge on second line
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
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
            ],
          ),
        ),
      ),
    );
  }
}
