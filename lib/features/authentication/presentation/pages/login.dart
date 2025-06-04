/*
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_final/main.dart';
import 'package:flutter_application_final/signUp.dart';
import 'package:flutter_application_final/sinUp.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'buttom.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisibility = false;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: Container(
                  width: 100,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  alignment: const AlignmentDirectional(0, -1),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 6, 94, 135), // Dark cyan-purple blend
                              Color.fromARGB(255, 84, 90, 95), // Complementary color
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'Welcome Back',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: SizedBox(
                                  width: 370,
                                  child: TextFormField(
                                    controller: _emailController,
                                    autofocus: true,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF57636C),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFFF1F4F8),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF1F4F8),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: SizedBox(
                                  width: 370,
                                  child: TextFormField(
                                    controller: _passwordController,
                                    autofocus: true,
                                    autofillHints: const [AutofillHints.password],
                                    obscureText: !_passwordVisibility,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF57636C),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFFF1F4F8),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF1F4F8),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _passwordVisibility
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFF57636C),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _passwordVisibility =
                                                !_passwordVisibility;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Don\'t have an account? ',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    TextSpan(
                                      text: ' Sign Up here',
                                      style: GoogleFonts.plusJakartaSans(
                                          color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const SignUpWidget()),
                                          );
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
                ),
              ),
            ],
          ),
        ),
        
        bottomNavigationBar: ReusableBottomButton(
          buttonText: 'Login',
          padding: 16.0,
          fontSize: 18.0,
          onPressed: () {
            _handleLogin();
          },
        ),
      ),
    );
  }

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Simulate an API call to get the user role (admin or member)
    String userRole = await fetchUserRoleFromDatabase(email);

    // Store the user role in shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userRole', userRole);

    // After this, navigate to your home screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()), // Replace with your desired screen
    );
  }

  Future<String> fetchUserRoleFromDatabase(String email) async {
    // Simulate a delay for fetching data from a database
    await Future.delayed(const Duration(seconds: 2));

    // You would replace this with actual backend code to fetch the user role
    if (email == "admin@example.com") {
      return "admin"; // Simulate admin role
    } else {
      return "member"; // Simulate member role
    }
  }
}
*/
