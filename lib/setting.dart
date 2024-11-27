import 'package:flutter/material.dart';
import 'package:flutter_application_final/main.dart';
import 'package:flutter_application_final/name.dart';
import 'package:flutter_application_final/soundOption.dart';
import 'package:flutter_application_final/time.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'basePage.dart';

class TentSettingsWidget extends StatefulWidget {
  final String id; // Add deviceId as a parameter

  const TentSettingsWidget({super.key, required this.id}); // Accept deviceId in the constructor

  @override
  State<TentSettingsWidget> createState() => _TentSettingsWidgetState();
}


class _TentSettingsWidgetState extends State<TentSettingsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isMuted = false; // Initial mute state

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    // Determine padding and sizing based on screen size
    final horizontalPadding = screenSize.width * 0.05;
    final containerHeight = screenSize.height * 0.1;
    final fontSizeTitle = screenSize.width * 0.05;
    final fontSizeSubtitle = screenSize.width * 0.045;
    final verticalSpacing = screenSize.height * 0.02;
        //final screenWidth = MediaQuery.of(context).size.width;

    //final screenWidth = MediaQuery.of(context).size.width;

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
// Adjust the padding as needed
                child: Container(
                      height: 85, // Set the fixed height of the box

                  decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
                    boxShadow: const [
                      BoxShadow(
                    blurRadius: 5,
                    color: Color.fromARGB(52, 2, 2, 2),
                    //offset: const Offset(0, 2),
                  ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                        8.0), // Optional: Padding around the content
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: fontSizeTitle, // Responsive text size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            height: 10), // Add space between title and subtitle
                        Text(
                          'Disconnected at 2PM on 27 AUG',
                          style: TextStyle(
                            fontSize: fontSizeTitle, // Responsive subtitle size
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //SizedBox(height: 0),

              // Reusable Setting Item for "Name Tent"
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
                      MaterialPageRoute(builder: (context) => const NameWidget(deviceId: '',)),
                    );
                  },
                ),
              ),
              SizedBox(height: verticalSpacing),

              // Reusable Setting Item for "Frequency of Alerts"
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

              // Reusable Setting Item for "Sound Option"
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

              // Remove Tent
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: SettingsItem(
                  title: 'Remove Tent',
                  subtitle: 'Removing this tent will delete its data',
                  containerHeight: containerHeight,
                  fontSizeTitle: fontSizeTitle,
                  fontSizeSubtitle: fontSizeSubtitle,
                  onTap: () {
                    // Show the pop-up dialog when tapped
      _showDeleteDialog(context, widget.id); // Pass deviceId to the dialog
                  },
                ),
              ),

              // SizedBox(height: verticalSpacing),

              // Mute with Switch
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
                child: SettingsItem(
                  title: 'Mute',
                  subtitle: 'Stop notifications',
                  containerHeight: containerHeight,
                  fontSizeTitle: fontSizeTitle,
                  fontSizeSubtitle: fontSizeSubtitle,
                  isSwitch: true,
                  switchValue: _isMuted,
                  onSwitchChanged: (value) {
                    setState(() {
                      _isMuted = value; // Update mute state
                    });
                  },
                ),
              ),
              SizedBox(height: verticalSpacing),

              //const SizedBox(height: 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

// warning pop-up dialog
class _showDeleteDialog {
  _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 30),
              Text('Delete Tent'),
            ],
          ),
          content: const Text(
              'Are you sure you want to delete this tent? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel',
                  style: TextStyle(color: Color.fromARGB(255, 80, 139, 194))),
            ),
            TextButton(
              onPressed: () {
                // Perform delete action here
               deleteDevice(id); // Call the delete method with deviceId

              Navigator.of(context).pop(); 
                Provider.of<DeviceManager>(context, listen: false)
                      .removeDevice(id);
                  Navigator.pop(context);
                  // Close the dialog after delete
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Method to delete the device from Hive (or your storage)
  void deleteDevice(String name) {
    final deviceBox = Hive.box('deviceBox');
    deviceBox.delete(name);  // Delete the device from Hive using the deviceId
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