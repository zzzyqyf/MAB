import 'package:flutter/material.dart';
import 'package:flutter_application_final/deviceMnanger.dart';
import 'package:flutter_application_final/main.dart';
import 'package:flutter_application_final/name.dart';
import 'package:flutter_application_final/soundOption.dart';
import 'package:flutter_application_final/time.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'basePage.dart';

class TentSettingsWidget extends StatefulWidget {
  final String deviceId; // Device ID passed from the parent widget (main class)
  //final String userRole; // User role passed from InvitationWidget

  TentSettingsWidget({super.key, required this.deviceId}); // Accept deviceId and userRole

  @override
  State<TentSettingsWidget> createState() => _TentSettingsWidgetState();
}

class _TentSettingsWidgetState extends State<TentSettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isMuted = false; // Initial mute state
  String userRole = "Admin"; // Default role, can be updated
   

   @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  _loadUserRole() async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      //userRole = prefs.getString('userRole') ?? "member"; // Default to member if not found
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
    final disconnectionTime = deviceManager.getDisconnectionTime(widget.deviceId);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: BasePage(
          title: 'Settings',
          showBackButton: true,
        ),
        body: SafeArea(
          top: true,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
                child: Container(
                  height: 85,
                  decoration: BoxDecoration(
                    color: Theme.of(context).secondaryHeaderColor,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 5,
                        color: Color.fromARGB(52, 2, 2, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          disconnectionTime,
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Conditionally render Name Tent if the user is Admin
              if (userRole == 'Admin') 
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SettingsItem(
                    title: 'Name Tent',
                    subtitle: 'Tent',
                    containerHeight: containerHeight,
                    fontSizeTitle: fontSizeTitle,
                    fontSizeSubtitle: fontSizeSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NameWidget(deviceId: widget.deviceId)),
                      );
                    },
                  ),
                ),
              SizedBox(height: verticalSpacing),

              // Other settings
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: SettingsItem(
                  title: 'Frequency of Alerts',
                  subtitle: 'Every 1 minute',
                  containerHeight: containerHeight,
                  fontSizeTitle: fontSizeTitle,
                  fontSizeSubtitle: fontSizeSubtitle,
                  onTap: () {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SoundWidget()),
                    );
                  },
                ),
              ),
              SizedBox(height: verticalSpacing),

              // Conditionally render Remove Tent if the user is Admin
              if (userRole == 'Admin') 
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SettingsItem(
                    title: 'Remove Tent',
                    subtitle: 'Removing this tent will delete its data',
                    containerHeight: containerHeight,
                    fontSizeTitle: fontSizeTitle,
                    fontSizeSubtitle: fontSizeSubtitle,
                    onTap: () {
                      DeleteDialog.show(context, widget.deviceId);
                    },
                  ),
                ),

              SizedBox(height: verticalSpacing),

              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
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
                  },
                ),
              ),
              SizedBox(height: verticalSpacing),
            ],
          ),
        ),
      ),
    );
  }
}

// warning pop-up dialog
class DeleteDialog {
  static void show(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Device'),
            ],
          ),
          content: const Text(
              'Are you sure you want to delete this device? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 80, 139, 194)),
              ),
            ),
            TextButton(
              onPressed: () {
                // Perform delete action here
                Provider.of<DeviceManager>(context, listen: false)
                    .removeDevice(id); // Remove the device using DeviceManager
                Navigator.of(context).pop();
                Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const MyApp()), // Replace with your desired screen
  ); // Close the dialog
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Reusable SettingsItem Widget
class SettingsItem extends StatelessWidget {
  
  final String title;
  final String subtitle;
  final double containerHeight;
  final double fontSizeTitle;
  final double fontSizeSubtitle;
  final VoidCallback? onTap; // Nullable to allow non-clickable items
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
    this.isSwitch = false, // Defaults to false (no switch)
    this.switchValue,
    this.onSwitchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap, // Makes the widget clickable if onTap is not null
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
                 Icon(Icons.arrow_forward_ios,
                size: screenWidth * 0.04,
                color: Colors.grey), 
            ],
          ),
        ),
      ),
    );
  }
}