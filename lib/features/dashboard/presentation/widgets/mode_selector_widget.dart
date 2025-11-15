import 'package:flutter/material.dart';
import '../models/mushroom_phase.dart';
import '../services/mode_controller_service.dart';
import '../../../../shared/services/TextToSpeech.dart';

/// Mode selector widget with toggle and timer for pinning mode
class ModeSelectorWidget extends StatefulWidget {
  final String deviceId;
  
  const ModeSelectorWidget({
    Key? key,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<ModeSelectorWidget> createState() => _ModeSelectorWidgetState();
}

class _ModeSelectorWidgetState extends State<ModeSelectorWidget> {
  late ModeControllerService _modeController;

  @override
  void initState() {
    super.initState();
    _modeController = ModeControllerService(deviceId: widget.deviceId);
    
    // Update UI every second to refresh countdown
    Future.delayed(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer() {
    if (mounted) {
      setState(() {});
      Future.delayed(const Duration(seconds: 1), _updateTimer);
    }
  }

  @override
  void dispose() {
    // Don't dispose singleton - it's shared across widgets
    // _modeController.dispose(); 
    super.dispose();
  }

  Future<void> _showTimerPicker() async {
    int selectedHours = 1;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Pinning Duration'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select how long to stay in Pinning mode:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: selectedHours > 1
                            ? () => setDialogState(() => selectedHours--)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$selectedHours ${selectedHours == 1 ? "hour" : "hours"}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: selectedHours < 24
                            ? () => setDialogState(() => selectedHours++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: selectedHours.toDouble(),
                    min: 1,
                    max: 24,
                    divisions: 23,
                    label: '$selectedHours hours',
                    onChanged: (value) {
                      setDialogState(() {
                        selectedHours = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    debugPrint('========================================');
                    debugPrint('🔴🔴🔴 ACTIVATE BUTTON PRESSED!!! 🔴🔴🔴');
                    debugPrint('✅ Timer Dialog: Activate button pressed with $selectedHours hours');
                    debugPrint('========================================');
                    Navigator.of(context).pop();
                    debugPrint('🚀 Timer Dialog: Calling setPinningMode($selectedHours)');
                    await _modeController.setPinningMode(selectedHours);
                    debugPrint('✅ Timer Dialog: setPinningMode() completed');
                    await TextToSpeech.speak(
                      'Pinning mode activated for $selectedHours ${selectedHours == 1 ? "hour" : "hours"}',
                    );
                  },
                  child: const Text('Activate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMode = _modeController.currentMode;
    final isPinning = currentMode == CultivationMode.pinning;
    final remainingTime = _modeController.formattedRemainingTime;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cultivation Mode',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  isPinning ? Icons.pin_drop : Icons.eco,
                  color: isPinning ? Colors.orange : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mode toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPinning ? 'Pinning Mode 🍄' : 'Normal Mode 🌱',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPinning ? Colors.orange : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        modeThresholds[currentMode]!.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isPinning,
                  onChanged: (bool value) async {
                    debugPrint('🎛️ Mode Switch: toggled to ${value ? "PINNING" : "NORMAL"}');
                    if (value) {
                      // Switching to Pinning - show timer picker
                      debugPrint('🎛️ Mode Switch: Showing timer picker for pinning mode');
                      await _showTimerPicker();
                    } else {
                      // Switching to Normal
                      debugPrint('🎛️ Mode Switch: Setting to Normal mode');
                      await _modeController.setNormalMode();
                      await TextToSpeech.speak('Switched to Normal mode');
                    }
                  },
                  activeColor: Colors.orange,
                ),
              ],
            ),
            
            // Countdown timer (only shown in pinning mode)
            if (isPinning && remainingTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.orange[700],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Time Remaining:',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      remainingTime,
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Mode thresholds
            _buildThresholdRow(
              'Regulating Humidity',
              '${modeThresholds[currentMode]!.minHumidity.toInt()}-${modeThresholds[currentMode]!.maxHumidity.toInt()}%',
              Icons.water_drop,
              Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            // ⏸️ Actuator status - Temporarily disabled for alarm system implementation
            /* 
            Text(
              'Actuator Status',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActuatorChip(
                  'Humidifier 1',
                  _modeController.humidifier1On,
                  Icons.cloud,
                ),
                _buildActuatorChip(
                  'Humidifier 2',
                  _modeController.humidifier2On,
                  Icons.cloud,
                ),
                _buildActuatorChip(
                  'Fan 1',
                  _modeController.fan1On,
                  Icons.air,
                ),
                _buildActuatorChip(
                  'Fan 2',
                  _modeController.fan2On,
                  Icons.air,
                ),
              ],
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /* ⏸️ Temporarily disabled actuator chip builder
  Widget _buildActuatorChip(String label, bool isOn, IconData icon) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: isOn ? Colors.white : Colors.grey[600],
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isOn ? Colors.white : Colors.grey[600],
        ),
      ),
      backgroundColor: isOn ? Colors.green : Colors.grey[200],
    );
  }
  */
}
