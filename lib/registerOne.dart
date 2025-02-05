import 'package:flutter/material.dart';
import 'package:flutter_application_final/TextToSpeech.dart';
import 'package:flutter_application_final/registerFour.dart';
import 'package:flutter_application_final/registerThree.dart';
import 'basePage.dart';
import 'buttom.dart';

class Register2Widget extends StatefulWidget {
  const Register2Widget({Key? key}) : super(key: key);

  @override
  State<Register2Widget> createState() => _Register2WidgetState();
}

class _Register2WidgetState extends State<Register2Widget> {
  final _formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Function to speak the text
  void _speakText(String text) {
    TextToSpeech.speak(text);
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
        bottomNavigationBar: ReusableBottomButton(
          buttonText: 'Next',
          padding: 16.0,
          fontSize: 18.0,
          onPressed: () {
            TextToSpeech.speak("Next button");
          },
          onDoubleTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Register4Widget(id: '',)),
            );
          },
        ),
      ),
    );
  }
}
