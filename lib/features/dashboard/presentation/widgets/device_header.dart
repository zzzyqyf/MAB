import 'package:flutter/material.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// Shared imports
import '../../../../shared/widgets/app_button.dart';

// Project imports
import '../../../profile/presentation/pages/setting.dart';

class DeviceHeader extends StatelessWidget {
  final String deviceName;
  final String deviceId;

  const DeviceHeader({
    Key? key,
    required this.deviceName,
    required this.deviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            deviceName,
            style: AppTextStyles.textTheme.headlineMedium?.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AppIconButton(
          icon: Icons.settings_sharp,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TentSettingsWidget(deviceId: deviceId),
              ),
            );
          },
          tooltip: 'Device Settings',
          semanticLabel: 'Open device settings',
        ),
      ],
    );
  }
}
