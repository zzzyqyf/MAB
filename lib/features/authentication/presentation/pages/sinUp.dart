import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/services/email_service.dart';
import '../../../../shared/widgets/buttom.dart';
import 'signIn.dart';
import 'otp_verification_page.dart';
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

  // Sign up method with OTP verification
  Future<void> _signUp() async {
    print('🚀 _signUp() called');
    print('📧 Current Firebase Auth user: ${FirebaseAuth.instance.currentUser?.email}');
    
    // Check if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      print('⚠️ User already logged in! Email: ${FirebaseAuth.instance.currentUser!.email}');
      TextToSpeech.speak('You are already logged in. Please logout first to create a new account.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already logged in. Please logout from the profile page to create a new account.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    if (_formKey.currentState?.validate() ?? false) {
      try {
        print('✅ Form validated, starting signup process...');
        
        // Show loading indicator
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        print('📧 Signup email: $email');

        // Step 1: Generate and send OTP
        final otp = EmailService.generateOTP();
        
        TextToSpeech.speak('Sending verification code to your email');
        
        final emailSent = await EmailService.sendOTP(
          email: email,
          otp: otp,
        );

        if (!emailSent) {
          // Close loading dialog
          if (!mounted) return;
          Navigator.of(context).pop();
          
          TextToSpeech.speak('Failed to send verification code. Please check your email and try again.');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send verification code. Please check your email and try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Step 2: Store OTP in Firestore
        print('📝 About to store OTP in Firestore...');
        try {
          await EmailService.storeOTP(
            email: email,
            otp: otp,
          );
          print('✅ OTP stored successfully, navigating to verification page...');
        } catch (firestoreError) {
          // Close loading dialog
          if (!mounted) return;
          Navigator.of(context).pop();
          
          print('❌ Firestore error: $firestoreError');
          
          TextToSpeech.speak('Failed to store verification code. Please check your internet connection and try again.');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Firestore error: ${firestoreError.toString()}. Please check Firebase configuration.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }

        // Close loading dialog
        if (!mounted) return;
        Navigator.of(context).pop();

        // Step 3: Navigate to OTP verification page
        TextToSpeech.speak('Verification code sent. Please check your email.');
        
        print('🚀 Navigating to OTP verification page...');
        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: email,
              password: password,
            ),
          ),
        );
        
        print('✅ Returned from OTP verification page. Verified: $verified');
        print('📋 Verified type: ${verified.runtimeType}');
        print('🔍 Verified == true: ${verified == true}');
        print('🔍 Verified is bool: ${verified is bool}');

        // Step 4: If OTP verified, create Firebase account
        if (verified == true) {
          print('✅ OTP verified successfully, creating Firebase account...');
          if (!mounted) return;
          
          // Show loading indicator again
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            print('🔐 Creating Firebase Auth user for: $email');
            
            // Create the user with email and password
            UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            print('✅ Firebase Auth user created: ${userCredential.user?.uid}');
            print('📝 Storing user data in Firestore...');

            // Add additional user data to Firestore
            await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
              'email': userCredential.user?.email,
              'role': 'member',
              'createdAt': FieldValue.serverTimestamp(),
              'emailVerified': true,
            });

            print('✅ User data stored in Firestore');
            print('🗑️ Deleting OTP document...');

            // Delete OTP document
            await EmailService.deleteOTP(email);

            print('✅ OTP document deleted');
            print('🎉 Account creation complete!');

            // Close loading dialog
            if (!mounted) return;
            Navigator.of(context).pop();

            print('✅ Loading dialog closed');

            // Show success message
            TextToSpeech.speak('Account created successfully. Welcome!');
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            print('🏠 AuthWrapper will now redirect to dashboard...');
            // Navigate to home screen - Firebase auth state will handle the redirect
          } catch (e) {
            // Close loading dialog
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }

            // Delete OTP on account creation failure
            await EmailService.deleteOTP(email);

            if (e is FirebaseAuthException) {
              String errorMessage = 'Sign up failed';
              
              switch (e.code) {
                case 'email-already-in-use':
                  errorMessage = 'This email is already registered. Please login instead.';
                  break;
                case 'invalid-email':
                  errorMessage = 'Invalid email address format.';
                  break;
                default:
                  errorMessage = 'Sign up failed. Please try again.';
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
            } else {
              TextToSpeech.speak('Sign up failed. Please try again.');
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sign up failed. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // OTP verification cancelled or failed
          TextToSpeech.speak('Verification cancelled');
        }
        
      } on FirebaseAuthException catch (e) {
        // Close loading dialog if it's open
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        String errorMessage = 'Sign up failed';
        
        // Handle only specific Firebase Auth errors as requested
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered. Please login instead.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address format.';
            break;
          default:
            errorMessage = 'Sign up failed. Please try again.';
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

        TextToSpeech.speak('Sign up failed. Please try again.');
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
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