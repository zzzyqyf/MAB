import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_application_final/registerOne.dart';
//import 'package:flutter_application_final/temp.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'ProfilePage.dart';
import 'Navbar.dart';
//import 'editProfile.dart';
import 'notification.dart';
//import 'addPage.dart';
//import 'setting.dart';
import 'tentPage.dart';
void main() {
  runApp(
    DevicePreview(
      enabled: true, // Enable the device preview
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true, // Enable media query for responsiveness
      builder: DevicePreview.appBuilder, // Wraps the app with DevicePreview
      locale: DevicePreview.locale(
          context), // Supports locale changes in DevicePreview
      title: 'Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Track the selected index

  // Define pages to navigate to
  final List<Widget> _pages = [
    const ProfilePage(),
    const notification(),
    const Register2Widget(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context); // Get screen dimensions

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: const AlignmentDirectional(0, -0.9),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  0,
                  mediaQuery.size.height * 0.06, // Responsive top padding
                  0,
                  0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PlantCare Hubs',
                    style: TextStyle(
                  fontWeight: FontWeight.w500,
                      fontSize:
                          mediaQuery.size.width * 0.07, // Responsive font size
                      letterSpacing: 0.0,
                     // fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
                0, mediaQuery.size.height * 0.15, 0, 5),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      0, mediaQuery.size.height * 0.02, 0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TentCard(
                        tentName: 'TENTNAME',
                        icon: Icons.wifi_off,
                        iconColor: Colors.red,
                        status: 'Critical',
                        onTap: () {
                          // Add your action here
                          print('First Tent tapped!');
                        },
                      ),
                      SizedBox(width: mediaQuery.size.width * 0.02),
                      TentCard(
                        tentName: 'TENTNAME',
                        icon: Icons.wifi_outlined,
                        iconColor: Colors.green,
                        status: 'Critical',
                        onTap: () {
                          // Add your action here
                          print('Second Tent tapped!');
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      0, mediaQuery.size.height * 0.01, 0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TentCard(
                        tentName: 'Room One',
                        icon: Icons.wifi_off,
                        iconColor: Colors.red,
                        status: 'Critical',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TentPage(), // Replace with your target page
                            ),
                          );
                        },
                      ),
                      SizedBox(width: mediaQuery.size.width * 0.02),
                      TentCard(
                        tentName: 'TENTNAME',
                        icon: Icons.wifi_outlined,
                        iconColor: Colors.green,
                        status: 'Critical',
                        onTap: () {
                          print('Fourth Tent tapped!');
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
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class TentCard extends StatelessWidget {
  final String tentName;
  final IconData icon;
  final Color iconColor;
  final String status;
  final VoidCallback onTap; // Add an onTap callback

  const TentCard({
    Key? key,
    required this.tentName,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.onTap, // Require an onTap callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return GestureDetector(
      // Wrap in GestureDetector
      onTap: onTap, // Handle the tap action
      child: Container(
        width: mediaQuery.size.width * 0.46,
        height: mediaQuery.size.width * 0.46,
       decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 6, 94, 135), // Dark cyan-purple blend
            Color.fromARGB(255, 84, 90, 95), // Complementary color
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
        child: Stack(
          children: [
            Align(
              alignment: const AlignmentDirectional(-0.40, -0.5),
              child: Text(
                tentName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize:
                      mediaQuery.size.width * 0.06, // Responsive font size
                ),
              ),
            ),
            Align(
              alignment: const AlignmentDirectional(-0.09, 0.11),
              child: Icon(
                icon,
                color: iconColor,
                size: mediaQuery.size.width * 0.09, // Responsive icon size
              ),
            ),
            Align(
              alignment: const AlignmentDirectional(-0.09, 0.63),
              child: Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize:
                      mediaQuery.size.width * 0.06, // Responsive font size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
