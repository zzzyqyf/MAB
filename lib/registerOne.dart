/*
import 'package:flutter/material.dart';
import 'package:flutter_application_final/registerFour.dart';
import 'package:flutter_application_final/registerThree.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
                _buildInstructionSection(context, screenWidth),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ReusableBottomButton(
        buttonText: 'Next',
        padding: 16.0,
        fontSize: 18.0,
        onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Register4Widget(id: '',)),
                );
                      },
      ),
      ),
    );
  }

  Widget _buildInstructionSection(BuildContext context, double screenWidth) {
    return Padding(
padding: const EdgeInsets.fromLTRB(
    55.0, // Left padding
    30.0,  // Top padding
    15.0, // Right padding
    20.0, // Bottom padding
  ),      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
           
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              
              ' Turn on Bluetooth\n\n'
              ' Find the ESP32 Device\n'
              ' in your smartphone\n\n'
              ' Pair with the ESP32\n\n'
              ' Click Next Button\n',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                fontSize: screenWidth * 0.055,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/