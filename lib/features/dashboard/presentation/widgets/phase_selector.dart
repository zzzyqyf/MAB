import 'package:flutter/material.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

// Shared imports
import '../../../../shared/services/TextToSpeech.dart';

// Model imports
import '../models/mushroom_phase.dart';

class PhaseSelector extends StatelessWidget {
  final MushroomPhase currentPhase;
  final Function(MushroomPhase) onPhaseChanged;

  const PhaseSelector({
    Key? key,
    required this.currentPhase,
    required this.onPhaseChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase selector label
          Text(
            'Cultivation Phase',
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: AppDimensions.spacing12),
          
          // Segmented control for phase selection
          _buildSegmentedControl(),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.onSurfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          // First row: Spawn Run and Primordia
          Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  MushroomPhase.spawnRun,
                  phaseThresholds[MushroomPhase.spawnRun]!,
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                child: _buildSegmentButton(
                  MushroomPhase.primordia,
                  phaseThresholds[MushroomPhase.primordia]!,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          // Second row: Fruiting and Post-Harvest
          Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  MushroomPhase.fruiting,
                  phaseThresholds[MushroomPhase.fruiting]!,
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                child: _buildSegmentButton(
                  MushroomPhase.postHarvest,
                  phaseThresholds[MushroomPhase.postHarvest]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(MushroomPhase phase, PhaseThresholds thresholds) {
    final isSelected = currentPhase == phase;
    
    return Semantics(
      label: '${thresholds.name} cultivation phase',
      hint: isSelected ? 'Currently selected' : 'Tap to select this phase',
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          onPhaseChanged(phase);
          TextToSpeech.speak('Phase changed to ${thresholds.name}');
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 75, // Fixed height for consistency
          padding: EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            mainAxisSize: MainAxisSize.min,
            children: [
              // Phase icon
              Text(
                thresholds.icon,
                style: TextStyle(
                  fontSize: 18, // Slightly smaller icon for better fit
                ),
              ),
              SizedBox(height: 4),
              // Phase name
              Flexible( // Allow text to shrink if needed
                child: Text(
                  thresholds.name,
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: isSelected 
                        ? Colors.white 
                        : AppColors.onSurface,
                    fontWeight: isSelected 
                        ? FontWeight.w600 
                        : FontWeight.w500,
                    fontSize: 14, // Smaller font size for better fit
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
