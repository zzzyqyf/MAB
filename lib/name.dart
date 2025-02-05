import 'package:flutter/material.dart';
import 'package:flutter_application_final/TextToSpeech.dart';
import 'package:flutter_application_final/basePage.dart';
import 'package:flutter_application_final/buttom.dart';
import 'package:flutter_application_final/deviceMnanger.dart';
import 'package:flutter_application_final/main.dart';
import 'package:flutter_application_final/setting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';


class NameWidget extends StatefulWidget {
  final String deviceId; // Device ID passed from the parent widget (main class)

  const NameWidget({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<NameWidget> createState() => _NameWidgetState();
  
}

class _NameWidgetState extends State<NameWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final padding = screenWidth * 0.04; // 4% of screen width
    final double fontSize = screenWidth * 0.04; // Responsive font size for labels

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: BasePage(
          title: 'Name Page',
          showBackButton: true,
        ),
        /*
        appBar: AppBar(
          title: const Text('Edit Name'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        */
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                    child: Column(
                      children: [
                       GestureDetector(
                          onTap: () => TextToSpeech.speak("Fill in the new Name below"), // Tap to hear again
                          child: Text(
                            'Fill in the new Name below',
                            style: GoogleFonts.outfit(fontSize: screenWidth * 0.05),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: const Color(0xFF57636C),
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFE0E3E7),
                                width: 2,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFFFF5963),
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.text,
                          cursorColor: Colors.blue,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                               Future.delayed(Duration(milliseconds: 500), () {
                    TextToSpeech.speak('Please enter a name');
                  });
                              TextToSpeech.speak('Please enter a name');
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: padding, horizontal: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
       bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(16.0),
  child: ReusableBottomButton(
    buttonText: 'Next',  // The text to display on the button
    padding: 16.0,       // Padding around the button
    fontSize: 18.0,      // Font size for the text
    onPressed: () {
          TextToSpeech.speak('Save Button');

    },
    onDoubleTap: () {
    // Double tap action
          if (_formKey.currentState?.validate() ?? false) {
        final name = _controller.text.trim();
        if (name.isNotEmpty) {
          final deviceId = widget.deviceId; // Get the deviceId passed in
          // Call the existing addDevice method from the main class
          Provider.of<DeviceManager>(context, listen: false).updateDeviceName(deviceId!, name);

          Navigator.pop(context);  // Close current page
          // Optionally, you can navigate to a new screen after the button press
          /*Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TentSettingsWidget(deviceId: deviceId)),
          );*/
                          TextToSpeech.speak('Back to Setting');

        }
      }

  },
  ),
),

      ),
    );
  }

  // This method would access the addDevice method from your main class or provider
  void _addDeviceFromMainClass(String deviceId, String name) {
    // Assuming you have a method in your main class (or any global provider) like this:
    // Provider.of<DeviceManager>(context, listen: false).addDevice(deviceId, name);
    
    // This is just an example. Modify it based on how you've structured your app.
    print('Device added with ID: $deviceId and Name: $name');
  }
}