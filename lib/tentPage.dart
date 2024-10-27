import 'package:flutter/material.dart';
import 'package:flutter_application_final/main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'Navbar.dart'; // Import CustomNavbar component
import 'ProfilePage.dart';
import 'notification.dart';
import 'setting.dart';

class TentPage extends StatefulWidget {
  const TentPage({super.key});

  @override
  _TentPageState createState() => _TentPageState();
}

class _TentPageState extends State<TentPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ProfilePage(),
    const notification(),
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
    final mediaQuery = MediaQuery.of(context); // Get screen dimensions

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final boxSize =
        screenWidth * 0.46; // Responsive box size based on screen width

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
                        0.09,
                        screenHeight * 0.06,
                        screenWidth * 0.045,
                        screenHeight * 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings_sharp,
                            color: Theme.of(context).primaryColor,
                            size: screenWidth * 0.1, // Responsive icon size
                          ),
                          onPressed: () {
                            // Navigate to another page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TentSettingsWidget(), // Replace with your target page
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Title Text
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        0, 0.5, 0, screenHeight * 0.05),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Overview',
                          style: Theme.of(context)
                              .textTheme
                             .bodyLarge!
                              .copyWith(
                                fontSize:
                                    screenWidth * 0.08, // Responsive font size
                                fontFamily: 'Outfit',
                              ),
                        ),
                        
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.zero,
                    // Two boxes for Humidity and Light Intensity
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBox(
                          context,
                          boxSize: boxSize,
                          icon: Icons.water_drop,
                          iconColor:Colors.blue,
                          title: 'Humidity',
                          value: '78.8%',
                          
                        ),
                        SizedBox(
                            width: mediaQuery.size.width *
                                0.02), // Horizontal spacing between boxes

                        _buildBox(
                          context,
                          boxSize: boxSize,
                          icon: Icons.lightbulb_outline,
                          iconColor:Colors.yellow,
                          title: 'Light Intensity',
                          value: 'Low',
                        ),
                        SizedBox(width: mediaQuery.size.width * 0.0),
                      ],
                    ),
                  ),
                  SizedBox(
                      height: mediaQuery.size.height *
                          0.01), // Vertical space between rows

                  // Temperature and Water Level Boxes
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
        onTap: () {
          // Add your action for Humidity box tap here
 Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MyApp(), // Replace with your target page
                            ),
                          );        },
                      child:  _buildBox(
                          context,
                          boxSize: boxSize,
                          icon: FontAwesomeIcons.temperatureFull,
                          iconColor: const Color.fromARGB(255, 221, 161, 76),
                          title: 'Temperture',
                          value: '29.0 C',
                        ),),
                        SizedBox(
                            width: mediaQuery.size.width *
                                0.02), // Horizontal spacing between boxes

                        _buildBox(
                          context,
                          boxSize: boxSize,
                          icon: Icons.water_sharp,
                          iconColor: Theme.of(context).colorScheme.error,
                          title: 'Water Level',
                          value: '50%',
                          
                        ),
                        SizedBox(width: mediaQuery.size.width * 0.0),
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
  }

  // Method to build a box with an icon and text
  Widget _buildBox(BuildContext context,
      {required double boxSize,
      required IconData icon,
      required Color iconColor,
      required String title,
      required String value}) {
    return Container(
      width: boxSize,
      height: boxSize,
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
            alignment: const AlignmentDirectional(0, -0.5),
            child: Icon(
              icon,
              color: iconColor,
              size: boxSize * 0.35, // Responsive icon size
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(0, 0.85),
            child: Text(
              title,
          
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: boxSize * 0.12, // Responsive text size
                    fontFamily: 'Outfit',
                          color: Colors.white, // Set text color to white

                  ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(0, 0.4),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: boxSize * 0.14, // Responsive text size
                    fontFamily: 'Outfit',
                          color: Colors.white, // Set text color to white

                  ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build an interactive box with a double-tap action
}
