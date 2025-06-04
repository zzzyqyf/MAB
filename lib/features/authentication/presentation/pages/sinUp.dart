import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/buttom.dart';
import '../../../../main.dart';
import 'signIn.dart';
//import 'home_screen.dart'; // Home screen widget, you can replace this with your actual home screen

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({Key? key}) : super(key: key);

  @override
  _SignUpWidgetState createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _passwordVisibility = false;
  bool _confirmPasswordVisibility = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Sign up method
  Future<void> _signUp() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      // Create the user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Add additional user data (e.g., role) to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'email': userCredential.user?.email,
        'role': 'member', // Default to member, you can add admin logic later
      });

      // Send an invitation email
     
      // Navigate to home screen after successful sign-up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
      );
    } catch (e) {
                  TextToSpeech.speak('Sign up failed');

      // Handle sign up errors (e.g., weak password, invalid email)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
    }
  }
}

  final scaffoldKey = GlobalKey<ScaffoldState>();

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
                                  alignment: Alignment.center,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                          onTap: () {
                            TextToSpeech.speak('Create Account');
                          },
                      /*
                      Container(
                        width: double.infinity,
                        height: 140,
                        alignment: const AlignmentDirectional(-1, 0),
                      ),
                      */
                    child:  ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 6, 94, 135),
                            Color.fromARGB(255, 84, 90, 95),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'Create Account',
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
                                            TextToSpeech.speak('Please enter your details');
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
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: SizedBox(
                                  width: 370,
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: !_confirmPasswordVisibility,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
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
                                          _confirmPasswordVisibility
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFF57636C),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _confirmPasswordVisibility =
                                                !_confirmPasswordVisibility;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        TextToSpeech.speak('Please confirm your password');
                                        return 'Please confirm your password';
                                      } else if (value !=
                                          _passwordController.text) {
                                            TextToSpeech.speak('Passwords do not match');
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              
                              GestureDetector(
                                  onTap: () {
                                    TextToSpeech.speak('Already have an account? Login here ');
                                  },
                                  onDoubleTap: () {
                                    TextToSpeech.speak('Navigating to Login page');
                                    Navigator.pushReplacement(
                                      context,
                                       MaterialPageRoute(builder: (context) => const LoginWidget()),

                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                      text: 'Already have an account? Login here ',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        TextSpan(
                                          text: 'Login here',
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
                              /*
                               ReusableBottomButton(
                                buttonText: 'Sign Up',
                                padding: 16.0,
                                fontSize: 18.0,
                                onPressed: 
                                  _signUp,// Hdle sign-up action here
                                
                              ),
                              
                               Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child:  ReusableBottomButton(
                                buttonText: 'Sign Up',
                                padding: 16.0,
                                fontSize: 18.0,
                                 onPressed: () {
            TextToSpeech.speak('Signup Button');
          }, 
                                  onDoubleTap: () { 
                                    _signUp();
                                   },// Hdle sign-up action here
                                
                              ),
                              ),
                             */
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
          buttonText: 'SignUp',
          padding: 16.0,
          fontSize: 18.0,
          onPressed: () {
            TextToSpeech.speak('Signup Button');
          },
          onDoubleTap: () async {
            TextToSpeech.speak('Signed Up in navigating to dashboard');
            // Double tap action
              _signUp();// Hdle sign-up action here
          },
        ),
    ),
  );
}
}