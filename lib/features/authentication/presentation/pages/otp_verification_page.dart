import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/services/email_service.dart';
import '../../../../shared/widgets/buttom.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String password;
  
  const OTPVerificationPage({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _otpControllers = 
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = 
      List.generate(6, (index) => FocusNode());
  
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    TextToSpeech.speak('Please enter the 6-digit code sent to your email');
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getOTP() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 60 seconds cooldown
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      // Generate new OTP
      final otp = EmailService.generateOTP();
      
      // Send email
      final emailSent = await EmailService.sendOTP(
        email: widget.email,
        otp: otp,
      );

      if (emailSent) {
        // Store in Firestore
        await EmailService.storeOTP(
          email: widget.email,
          otp: otp,
        );

        TextToSpeech.speak('New verification code sent to your email');
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New verification code sent!'),
            backgroundColor: Colors.green,
          ),
        );

        _startResendCountdown();
      } else {
        TextToSpeech.speak('Failed to send verification code');
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      TextToSpeech.speak('Error sending verification code');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _getOTP();
    
    if (otp.length != 6) {
      TextToSpeech.speak('Please enter all 6 digits');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Verify OTP
      final result = await EmailService.verifyOTP(
        email: widget.email,
        inputOtp: otp,
      );

      if (!mounted) return;

      if (result['success']) {
        TextToSpeech.speak('Email verified successfully');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Return success to signup page
        Navigator.of(context).pop(true);
      } else {
        TextToSpeech.speak(result['message']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      TextToSpeech.speak('Error verifying code');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building OTP Verification Page for email: ${widget.email}');
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              print('🔙 Back button pressed, returning false');
              Navigator.of(context).pop(false);
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Title
                GestureDetector(
                  onTap: () {
                    TextToSpeech.speak('Verify Your Email');
                  },
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 6, 94, 135),
                        Color.fromARGB(255, 84, 90, 95),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Verify Your Email',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Description
                GestureDetector(
                  onTap: () {
                    TextToSpeech.speak('We have sent a 6-digit verification code to ${widget.email}');
                  },
                  child: Text(
                    'We\'ve sent a 6-digit code to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: const Color(0xFF57636C),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
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
                        onChanged: (value) {
                          if (value.length == 1 && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          
                          // Auto-verify when all 6 digits entered
                          if (index == 5 && value.isNotEmpty) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 32),
                
                // Resend OTP
                GestureDetector(
                  onTap: _resendCountdown == 0 && !_isResending ? _resendOTP : null,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Didn\'t receive the code? ',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: _resendCountdown > 0
                              ? 'Resend in $_resendCountdown s'
                              : _isResending
                                  ? 'Sending...'
                                  : 'Resend',
                          style: GoogleFonts.plusJakartaSans(
                            color: _resendCountdown > 0 || _isResending
                                ? Colors.grey
                                : Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Loading indicator
                if (_isVerifying)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ReusableBottomButton(
          buttonText: 'Verify',
          padding: 16.0,
          fontSize: 18.0,
          onPressed: () {
            TextToSpeech.speak('Verify button');
          },
          onDoubleTap: () async {
            TextToSpeech.speak('Verifying code');
            _verifyOTP();
          },
        ),
      ),
    );
  }
}
