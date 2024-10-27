import 'package:flutter/material.dart';
import 'package:flutter_application_final/setting.dart';
import 'package:google_fonts/google_fonts.dart';

import 'basePage.dart';
import 'buttom.dart';

class NameWidget extends StatefulWidget {
  const NameWidget({Key? key}) : super(key: key);

  @override
  State<NameWidget> createState() => _NameWidgetState();
}

class _NameWidgetState extends State<NameWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailAddressController = TextEditingController();
  final FocusNode _emailAddressFocusNode = FocusNode();

  @override
  void dispose() {
    _emailAddressController.dispose();
    _emailAddressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        final screenSize = MediaQuery.of(context).size;

    final screenWidth = MediaQuery.of(context).size.width;
        final padding = screenSize.width * 0.04; // 4% of screen width
            final double fontSize = screenSize.width * 0.04; // Responsive font size for labels



    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: BasePage(
          title: 'Edit Name',
          showBackButton: true,
        ),
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
                        Text(
                          'Fill in the new Name below',
                          style:
                              GoogleFonts.outfit(fontSize: screenWidth * 0.05),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailAddressController,
                          focusNode: _emailAddressFocusNode,
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
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Colors.blue,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            // Add further validation if needed
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
        bottomNavigationBar: ReusableBottomButton(
        buttonText: 'Next',
        padding: 16.0,
        fontSize: 18.0,
        onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TentSettingsWidget()),
                );
                      },
      ),
      ),
    );
  }
}
