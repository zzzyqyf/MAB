import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_final/TempVsTimeGraph.dart';
import 'package:flutter_application_final/deviceMnanger.dart';
import 'package:flutter_application_final/graph.dart';
import 'package:flutter_application_final/main.dart';
import 'package:flutter_application_final/tempertureGraph.dart';
import 'package:flutter_application_final/TextToSpeech.dart'; // Import your TTS class
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'Navbar.dart';
import 'ProfilePage.dart';
import 'notification.dart';
import 'setting.dart';

class TentPage extends StatefulWidget {
  final String id; // Unique device ID
  final String name; // Unique device name

  TentPage({required this.id, required this.name});

  @override
  _TentPageState createState() => _TentPageState();
}

class _TentPageState extends State<TentPage> {
  late DeviceManager deviceManager;

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ProfilePage(),
    const NotificationPage(),
    const MyApp(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final boxSize = screenWidth * 0.46;
        final deviceManager = Provider.of<DeviceManager>(context);

int deviceIndex = deviceManager.devices.indexWhere((d) => d['id'] == widget.id);

    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
           // final deviceManager = Provider.of<DeviceManager>(context);

        final sensorData = deviceManager.sensorData;
         // var device = deviceManager.devices[index];
  var device = deviceManager.devices[deviceIndex]; // Get the device at that index

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: const AlignmentDirectional(0, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Settings Icon
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            0.09, screenHeight * 0.06, screenWidth * 0.045, screenHeight * 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.settings_sharp,
                                color: Theme.of(context).primaryColor,
                                size: screenWidth * 0.1,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TentSettingsWidget(deviceId: widget.id),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Title Text
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 0.9, 0, screenHeight * 0.05),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.name,
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontSize: screenWidth * 0.08,
                                    fontFamily: 'Outfit',
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Humidity and Light Intensity Boxes
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            
                            _buildBox(
                              context,
                              boxSize: boxSize,
                              icon: Icons.water_drop,
                              iconColor: Colors.blue,
                             title: 'Humidity',
                              value: '${sensorData['humidity'] ?? 'Loading...'} %',
status: device['sensorStatus'] == 'low Humidity' 
    ? 'Low Humidity' 
    : '',

                              onDoubleTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HumVsTimeGraph(deviceId: widget.id),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: mediaQuery.size.width * 0.02),
                            _buildBox(
                              context,
                              boxSize: boxSize,
                              icon: Icons.lightbulb_outline,
                              iconColor: Colors.yellow,
                              title: 'Light Intensity',
                              value: '${sensorData['lightState'] ?? 'Loading...'} %',
                              status: device['sensorStatus'] == 'high lightIntensity' 
    ? 'high light' 
    : '', // This should be updated when sensor status changes

                              onDoubleTap: () {
                                // Add navigation logic if needed
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: mediaQuery.size.width * 0.02),
                      // Temperature and Water Level Boxes
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBox(
                              context,
                              boxSize: boxSize,
                              icon: FontAwesomeIcons.temperatureFull,
                              iconColor: const Color.fromARGB(255, 221, 161, 76),
                              title: 'Temperature',
                              value: '${sensorData['temperature'] ?? 'Loading...'} °C',
                              status: device['sensorStatus'] == 'High Temperture' 
    ? 'High Temperture' 
    : '', // This should be updated when sensor status changes

                              onDoubleTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TempVsTimeGraph(deviceId: widget.id),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: mediaQuery.size.width * 0.02),
                            _buildBox(
                              context,
                              boxSize: boxSize,
                              icon: Icons.water_sharp,
                              iconColor: Theme.of(context).colorScheme.error,
                              title: 'Water Level',
                              value: '50%',
                              status: device['sensorStatus'] == 'low waterLevel' 
    ? 'Low water' 
    : '', // This should be updated when sensor status changes
 // Replace with actual data when available
                              onDoubleTap: () {
                                // Add navigation logic if needed
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomNavbar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        );
      },
    );
  }

  Widget _buildBox(BuildContext context,
      {required double boxSize,
      required IconData icon,
      required Color iconColor,
      required String title,
      required String value,
      required String status,
      VoidCallback? onDoubleTap}) {
    return GestureDetector(
      onTap: () {
        // Single tap triggers TTS
        TextToSpeech.speak('$title: $value :$status');

      },
      onDoubleTap: onDoubleTap, // Double tap triggers navigation
      child: Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 6, 94, 135),
              Color.fromARGB(255, 84, 90, 95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Align(
              alignment: const AlignmentDirectional(0, -0.5),
              child: Icon(
                icon,
                color: iconColor,
                size: boxSize * 0.35,
              ),
            ),
            
            /*Align(
              alignment: const AlignmentDirectional(0, 0.85),
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: boxSize * 0.12,
                      fontFamily: 'Outfit',
                      color: Colors.white,
                    ),
              ),
            ),*/
            
            Align(
              alignment: const AlignmentDirectional(0, 0.85),
              child: Text(
                status,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: boxSize * 0.12,
                      fontFamily: 'Outfit',
                      color: Colors.white,
                    ),
              ),
            ),
            Align(
              alignment: const AlignmentDirectional(0, 0.4),
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: boxSize * 0.14,
                      fontFamily: 'Outfit',
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
