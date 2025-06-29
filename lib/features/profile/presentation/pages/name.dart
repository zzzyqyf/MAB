import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/buttom.dart';
import '../../../device_management/presentation/viewmodels/deviceManager.dart';


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
        appBar: const BasePage(
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
                               Future.delayed(const Duration(milliseconds: 500), () {
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

    },    onDoubleTap: () {
      // Double tap action
      if (_formKey.currentState?.validate() ?? false) {
        final name = _controller.text.trim();
        if (name.isNotEmpty) {
          final deviceId = widget.deviceId; // Get the deviceId passed in
          
          // Update device name
          Provider.of<DeviceManager>(context, listen: false).updateDeviceName(deviceId, name);
          
          // Provide feedback
          TextToSpeech.speak('Device name updated to $name. Going back to settings.');
          
          // Navigate back
          Navigator.pop(context);
        }
      }
    },
  ),
),      ),
    );
  }
}