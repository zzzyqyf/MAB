import 'package:flutter/material.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import 'register4_provider.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/buttom.dart';
import '../../../../shared/widgets/Navbar.dart';
import '../../../profile/presentation/pages/ProfilePage.dart';
import '../../../notifications/presentation/pages/notification.dart';
import '../../../../main.dart';

class Register2Widget extends StatefulWidget {
  const Register2Widget({Key? key}) : super(key: key);

  @override
  State<Register2Widget> createState() => _Register2WidgetState();
}

class _Register2WidgetState extends State<Register2Widget> {
  final _formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1; // Add Device/Registration page is index 1

  // Function to speak the text
  void _speakText(String text) {
    TextToSpeech.speak(text);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to Profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
      case 1:
        // Already on Add Device/Registration page, do nothing
        break;
      case 2:
        // Navigate to Notifications page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white, // Use your desired background color
        appBar: BasePage(
          title: 'Activate Device',
          showBackButton: true,
          onBackPressed: () {
            // Navigate back to main Dashboard page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyHomePage(title: 'PlantCare Hubs')),
            );
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Form(
                  key: _formKey,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 770,
                      maxHeight: screenHeight * 0.1,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                // Instruction Section
                GestureDetector(
                  onTap: () {
                    _speakText('Go to Wifi in your Phone. Find the ESP32 Network. Connect to ESP32. Return to this screen. Click Next Button below.');
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 6, 94, 135), // Dark cyan-purple blend
                        Color.fromARGB(255, 84, 90, 95), // Complementary color
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Go to Wifi in your Phone\n\n'
                      'Find the ESP32 Network\n'
                      'Connect to ESP32\n\n'
                      'Return to this screen\n\n'
                      'Click Next Button below\n',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.055,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReusableBottomButton(
              buttonText: 'Next',
              padding: 16.0,
              fontSize: 18.0,
              onPressed: () {
                TextToSpeech.speak("Next button");
              },
              onDoubleTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Register4ProviderWidget(id: ''),
                  ),
                );
              },
            ),
            CustomNavbar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ],
        ),
      ),
    );
  }
}
