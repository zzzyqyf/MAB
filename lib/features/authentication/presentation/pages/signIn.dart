import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/buttom.dart';
import '../../../../main.dart';
import 'sinUp.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisibility = false;
  final _formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  // Login method
  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Show loading indicator
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Authenticate user with email and password
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Close loading dialog
        if (!mounted) return;
        Navigator.of(context).pop();

        TextToSpeech.speak('Login successful. Welcome back!');

        // Navigate to the home screen explicitly
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage(title: 'PlantCare Hubs')),
          (route) => false, // Remove all previous routes
        );
        
      } on FirebaseAuthException catch (e) {
        // Close loading dialog if it's open
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        String errorMessage = 'Login failed';

        // Handle only specific Firebase Auth errors as requested
        switch (e.code) {
          case 'invalid-email':
            errorMessage = 'Invalid email address format.';
            break;
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage = 'Invalid email or password. Please try again.';
            break;
          default:
            errorMessage = 'Login failed. Please try again.';
        }

        TextToSpeech.speak(errorMessage);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } catch (e) {
        // Close loading dialog if it's open
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        TextToSpeech.speak('Login failed. Please try again.');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            TextToSpeech.speak('Welcome Back');
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
                              'Welcome Back',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: SizedBox(
                                    width: 370,
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autofocus: true,
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
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          Future.delayed(const Duration(milliseconds: 500), () {
                                            TextToSpeech.speak('Please enter your email');
                                          });
                                          return 'Please enter your email';
                                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                            .hasMatch(value)) {
                                          Future.delayed(const Duration(milliseconds: 500), () {
                                            TextToSpeech.speak('Please enter a valid email address');
                                          });
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: SizedBox(
                                    width: 370,
                                    child: TextFormField(
                                      controller: _passwordController,
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
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          Future.delayed(const Duration(milliseconds: 500), () {
                                            TextToSpeech.speak('Please enter your password');
                                          });
                                          return 'Please enter your password';
                                        } else if (value.length < 6) {
                                          TextToSpeech.speak('Password must be at least 6 characters');
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    TextToSpeech.speak('Don\'t have an account? signup here');
                                  },                                  onDoubleTap: () {
                                    TextToSpeech.speak('Navigating to Sign Up page');
                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SignUpWidget(),
                                        ),
                                      );
                                    }
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Don\'t have an account? ',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        TextSpan(
                                          text: 'Sign Up here',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.blue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
            TextToSpeech.speak('Login Button');
          },
          onDoubleTap: () async {
            TextToSpeech.speak('Logged in navigating to dashboard');
            // Double tap action
            _login();
          },
        ),
      ),
    );
  }
}
 