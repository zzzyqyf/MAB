import 'package:flutter/material.dart';
//import 'package:flutter_application_final/registerThree.dart';
//import 'package:google_fonts/google_fonts.dart';

import 'basePage.dart';
import 'buttom.dart';
import 'loadingO.dart';

class Register4Widget extends StatefulWidget {
  const Register4Widget({Key? key}) : super(key: key);

  @override
  State<Register4Widget> createState() => _Register4WidgetState();
}

class _Register4WidgetState extends State<Register4Widget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _passwordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white, // Use your desired background color
        appBar: BasePage(
        title: 'Connect to Wifi',
        showBackButton: true,
      ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Padding(
padding: const EdgeInsets.fromLTRB(
    10.0, // Left padding
    20.0,  // Top padding
    15.0, // Right padding
    5.0, // Bottom padding
  ),                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      'Fill in the Wi-Fi Password',
                      style: TextStyle(
                  fontWeight: FontWeight.w500,
                        fontSize: 20,
                        letterSpacing: 0.0,
                      ),
                    ),                    // const      SizedBox(height: 5),

                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Color(0xFF57636C),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFE0E3E7), width: 2),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(24),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF57636C),
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      cursorColor: const Color.fromARGB(255, 60, 57, 239),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 300),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: ReusableBottomButton(
        buttonText: 'Save',
        padding: 16.0,
        fontSize: 18.0,
        onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoadingWidget()),
                );
                      },
      ),
      ),
    );
  }
}
