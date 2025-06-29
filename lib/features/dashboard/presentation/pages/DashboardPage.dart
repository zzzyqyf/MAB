import 'package:flutter/material.dart';
import '../../../../shared/widgets/mushroom_icon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/services/TextToSpeech.dart';

class DashboardPage extends StatelessWidget {
  final List<Map<String, String>> devices; // List of devices passed from Register4Widget

  const DashboardPage({Key? key, required this.devices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const MushroomIcon(
              size: 28,
              color: Colors.white,
              semanticLabel: 'Mushroom decoration in app bar',
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: AppDimensions.elevationMedium,
        centerTitle: false,
        actions: [
          Semantics(
            label: 'Device count: ${devices.length} devices',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${devices.length}',
                style: AppTextStyles.buttonTextMedium.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: devices.isEmpty
            ? _buildEmptyState()
            : _buildDevicesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MushroomIconSet(
              iconSize: 64,
              spacing: 16,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(
                  color: AppColors.outline,
                  width: AppDimensions.borderMedium,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.devices,
                    size: AppDimensions.iconXXLarge,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Devices Connected',
                    style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first device to get started monitoring your IoT sensors.',
                    style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Devices list
          Expanded(
            child: ListView.separated(
              itemCount: devices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = devices[index];
                return _buildDeviceCard(device, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, String> device, int index) {
    return Builder(
      builder: (context) {
        // Determine status colors for high contrast
        Color statusColor;
        Color cardColor;
        IconData statusIcon;
        
        switch (device['status']?.toLowerCase()) {
          case 'online':
            statusColor = AppColors.success;
            cardColor = AppColors.successContainer;
            statusIcon = Icons.wifi;
            break;
          case 'offline':
            statusColor = AppColors.error;
            cardColor = AppColors.errorContainer;
            statusIcon = Icons.wifi_off;
            break;
          default:
            statusColor = AppColors.warning;
            cardColor = AppColors.warningContainer;
            statusIcon = Icons.sync;
        }

        return Semantics(
          label: 'Device ${device['name']}, ID ${device['id']}, Status ${device['status']}. Tap to hear details, double tap to open device.',
          child: GestureDetector(
            onTap: () async {
              // Single tap - announce device details via TTS
              final announcement = 'Device ${device['name'] ?? 'Unknown'}, '
                  'ID ${device['id'] ?? 'Unknown'}, '
                  'Status ${device['status'] ?? 'Unknown'}. '
                  'Double tap to open device details.';
              
              await TextToSpeech.speak(announcement);
            },
            onDoubleTap: () async {
              // Double tap - navigate to device details
              await TextToSpeech.speak('Opening ${device['name']} details');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening ${device['name']} - Device ID: ${device['id']}',
                    style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(
                  color: statusColor,
                  width: AppDimensions.borderThick,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with status and mushroom
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        child: Icon(
                          statusIcon,
                          color: AppColors.onPrimary,
                          size: AppDimensions.iconMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          device['name'] ?? 'Unknown Device',
                          style: AppTextStyles.textTheme.titleLarge?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      MushroomIcon(
                        size: 28,
                        color: statusColor,
                        semanticLabel: 'Device status indicator',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Device details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: AppColors.outline,
                        width: AppDimensions.borderThin,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Device ID', device['id'] ?? 'Unknown'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Status', device['status'] ?? 'Unknown'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Position', '${index + 1} of ${devices.length}'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: AppDimensions.borderThin,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: AppColors.primary,
                          size: AppDimensions.iconSmall,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap: Hear details • Double-tap: Open device',
                            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
