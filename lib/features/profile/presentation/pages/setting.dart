import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/buttom.dart';
import '../../../device_management/presentation/viewmodels/deviceManager.dart';
import '../../../../main.dart';
import 'name.dart';
import '../../../../shared/widgets/basePage.dart';
//import 'text_to_speech.dart'; // Assuming TTS utility is in text_to_speech.dart

class TentSettingsWidget extends StatefulWidget {
  final String deviceId;

  const TentSettingsWidget({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<TentSettingsWidget> createState() => _TentSettingsWidgetState();
}

class _TentSettingsWidgetState extends State<TentSettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String userRole = "Admin"; // Default role

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  _loadUserRole() async {
    setState(() {
      // Load user role here
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width * 0.05;
    final containerHeight = screenSize.height * 0.1;
    final fontSizeTitle = screenSize.width * 0.05;
    final fontSizeSubtitle = screenSize.width * 0.045;
    final verticalSpacing = screenSize.height * 0.02;

    final deviceManager = Provider.of<DeviceManager>(context);
    
    // Get the device to access mqttId (MAC address)
    final device = deviceManager.devices.firstWhere(
      (d) => d['id'] == widget.deviceId,
      orElse: () => <String, dynamic>{},
    );
    final mqttId = device['mqttId'] ?? 'N/A';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: const BasePage(
          title: 'Settings',
          showBackButton: true,
        ),
        body: SafeArea(
          top: true,
          child: ListView(
            children: [
// MAC Address (MQTT ID) Section - Replaces both Status and Device ID
Padding(
  padding: EdgeInsets.fromLTRB(horizontalPadding, 20.0, horizontalPadding, 15.0),
  child: GestureDetector(
    onTap: () {
      // Trigger TTS to read the MAC address
      TextToSpeech.speak('Device MAC Address $mqttId');
    },
    child: Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            color: Theme.of(context).cardColor,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MAC Address',
              style: GoogleFonts.outfit(
                fontSize: fontSizeTitle,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF101213),
              ),
            ),
            Text(
              mqttId,
              style: GoogleFonts.outfit(
                fontSize: fontSizeSubtitle,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  ),
),

              if (userRole == 'Admin')
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SettingsItem(
                    title: 'Name Device',
                    subtitle: 'Edit Device Name',
                    containerHeight: containerHeight,
                    fontSizeTitle: fontSizeTitle,
                    fontSizeSubtitle: fontSizeSubtitle,
                    onTap: () {
                      TextToSpeech.speak('Name the Device.');
                    },                    onDoubleTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider.value(
                            value: Provider.of<DeviceManager>(context, listen: false),
                            child: NameWidget(deviceId: widget.deviceId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: verticalSpacing),
              /*
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: SettingsItem(
                  title: 'Frequency of Alerts',
                  subtitle: 'Every 1 minute',
                  containerHeight: containerHeight,
                  fontSizeTitle: fontSizeTitle,
                  fontSizeSubtitle: fontSizeSubtitle,
                  onTap: () {
                    TextToSpeech.speak(
                        'Frequency of Alerts. Tap again to navigate.');
                  },
                  onDoubleTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const time()),
                    );
                  },
                ),
              ),
              SizedBox(height: verticalSpacing),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: SettingsItem(
                  title: 'Sound Option',
                  subtitle: 'PopCorn',
                  containerHeight: containerHeight,
                  fontSizeTitle: fontSizeTitle,
                  fontSizeSubtitle: fontSizeSubtitle,
                  onTap: () {
                    TextToSpeech.speak('Sound Option.');
                  },
                  onDoubleTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SoundWidget()),
                    );
                  },
                ),
              ),
              SizedBox(height: verticalSpacing),              */
              if (userRole == 'Admin')
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SettingsItem(
                    title: 'Remove Device',
                    subtitle: 'Data will be deleted',
                    containerHeight: containerHeight,
                    fontSizeTitle: fontSizeTitle,
                    fontSizeSubtitle: fontSizeSubtitle,
                    onTap: () {
                      TextToSpeech.speak(
                          'Remove Device. Removing this tent will delete its data.');
                    },
                    onDoubleTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  DeletePage(id:  widget.deviceId,)),
                    );
                      //DeletePage
                      //DeleteDialog.show(context, widget.deviceId);
                    },
                  ),
                ),
              SizedBox(height: verticalSpacing),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: SettingsItem(
                  title: 'Mute',
                  subtitle: 'Stop notifications',
                  containerHeight: containerHeight,
                  fontSizeTitle: fontSizeTitle,
                  fontSizeSubtitle: fontSizeSubtitle,
                  isSwitch: true,
                  switchValue: deviceManager.isMuted,
                  onSwitchChanged: (value) {
                    deviceManager.toggleMute(value);
                    if (value) {
                      TextToSpeech.speak('Device Muted');
                    } else {
                      TextToSpeech.speak('Device unmuted');
                    }
                  },
                   onTap: () {
                      TextToSpeech.speak(
                          'Mute Device. Stop receiving pop up notifications');
                          
                    },
                    
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class DeletePage extends StatelessWidget {
  final String id;

  const DeletePage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextToSpeech.speak(
        'Delete Device. Are you sure you want to delete this device? This action cannot be undone.');

    return Scaffold(
      appBar: const BasePage(
        title: 'Delete Page',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to delete this device? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ReusableBottomButton(
              buttonText: 'Delete',
              padding: 16.0,
              fontSize: 18.0,
              onPressed: () async {
                if (!context.mounted) return;
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                try {
                  // Get DeviceManager
                  final deviceManager = Provider.of<DeviceManager>(context, listen: false);
                  
                  // Remove device and wait for completion
                  await deviceManager.removeDevice(id);
                  
                  // Force Hive to flush changes to disk
                  await Hive.box('devices').compact();
                  
                  // Wait a moment for all cleanup to complete
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  if (!context.mounted) return;
                  
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  // Navigate back to dashboard by popping all routes until home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } catch (e) {
                  debugPrint('❌ Error removing device: $e');
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error removing device: $e')),
                    );
                  }
                }
              },
              onDoubleTap: () async {
                TextToSpeech.speak('Device Deleted');
                
                if (!context.mounted) return;
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                try {
                  // Get DeviceManager
                  final deviceManager = Provider.of<DeviceManager>(context, listen: false);
                  
                  // Remove device and wait for completion
                  await deviceManager.removeDevice(id);
                  
                  // Force Hive to flush changes to disk
                  await Hive.box('devices').compact();
                  
                  // Wait a moment for all cleanup to complete
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  if (!context.mounted) return;
                  
                  // Close loading dialog
                  Navigator.of(context).pop();
                  
                  // Navigate back to dashboard by popping all routes until home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } catch (e) {
                  debugPrint('❌ Error removing device: $e');
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error removing device: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final double containerHeight;
  final double fontSizeTitle;
  final double fontSizeSubtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool? isSwitch;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;

  const SettingsItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.containerHeight,
    required this.fontSizeTitle,
    required this.fontSizeSubtitle,
    this.onTap,
    this.onDoubleTap,
    this.isSwitch = false,
    this.switchValue,
    this.onSwitchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        height: containerHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              color: Theme.of(context).cardColor,
              offset: const Offset(0, 2),
            )
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF101213),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: fontSizeSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSwitch ?? false)
                Switch(
                  value: switchValue ?? false,
                  onChanged: onSwitchChanged,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                ),
              if (!(isSwitch ?? false))
                Icon(
                  Icons.arrow_forward_ios,
                  size: screenWidth * 0.04,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
