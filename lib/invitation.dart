import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_final/TextToSpeech.dart';
import 'ProfilePage.dart';
import 'basePage.dart';
import 'buttom.dart';
import 'package:http/http.dart' as http;

class InvitationWidget extends StatefulWidget {
  final String deviceId; // Device ID passed from the parent widget (main class)

  const InvitationWidget({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<InvitationWidget> createState() => _InvitationWidgetState();
}

class _InvitationWidgetState extends State<InvitationWidget> {
  final _emailAddressTextController = TextEditingController();
  final _emailAddressFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedRole; // To track the selected role
String senderEmail = FirebaseAuth.instance.currentUser!.email!;

  @override
  void dispose() {
    _emailAddressTextController.dispose();
    _emailAddressFocusNode.dispose();
    super.dispose();
  }

  // Function to send email invitation dynamically using the logged-in user's email
  // This function can be called after the sign-up process is successful





Future<void> sendInvitation(String senderEmail, String email, String role, String deviceId) async {
  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
                        String email = _emailAddressTextController.text.trim();

  const serviceId = 'service_ttwl1yt'; // Replace with your actual Service ID
  const templateId = 'template_f66pszr'; // Replace with your actual Template ID
  const publicKey = 'gHzghGoNvlAikljf7'; // Replace with your actual Public Key

  final headers = {
    'origin':'http://localhost',
    'Content-Type': 'application/json',
  };

  final body = json.encode({
    'service_id': serviceId,
    'template_id': templateId,
    'user_id': publicKey, // Add Public Key here
    'template_params': {
      'sender_email': senderEmail,
      'recipient_Email': email,
      'role': role,
      'device_id': deviceId,
    },
  });
//alifatima.x01@gmail.com

  try {
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
                      TextToSpeech.speak('Email sent successfully!');

      print('Email sent successfully! $senderEmail');
    } else {
      print('Failed to send email. Response: ${response.statusCode}');
      print('Response body: ${response.body} $email');
    }
  } catch (e) {
                          TextToSpeech.speak('Error sending email');

    print('Error sending email: $e');
  }
}
  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04; // 4% of screen width
    final textFieldWidth = screenSize.width * 0.9; // 90% of screen width
    const boxHeight = 60.0; // Fixed height for all input boxes
    final double fontSize = screenSize.width * 0.04; // Responsive font size for labels

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: const BasePage(
          title: 'Invitation',
          showBackButton: true,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: padding),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const SizedBox(height: 20),
                          SizedBox(
                            width: textFieldWidth,
                            child: TextFormField(
                              controller: _emailAddressTextController,
                              focusNode: _emailAddressFocusNode,
                              autofocus: true,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                labelText: 'Email',
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
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                   Future.delayed(const Duration(milliseconds: 500), () {
                    TextToSpeech.speak('Please enter an email address and select a role');
                  });
                                  return 'Please enter an email address';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRoleSelection(
                            context,
                            'Admin',
                            _selectedRole == 'Admin',
                            () {
                              setState(() {
                                _selectedRole = 'Admin'; // Set selected role
                              });
                            },
                            textFieldWidth,
                            boxHeight,
                          ),
                          const SizedBox(height: 12),
                          _buildRoleSelection(
                            context,
                            'Member',
                            _selectedRole == 'Member',
                            () {
                              setState(() {
                                _selectedRole = 'Member'; // Set selected role
                              });
                            },
                            textFieldWidth,
                            boxHeight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: padding, horizontal: 16),
                  child: ReusableBottomButton(
                    buttonText: 'Next',
                    padding: 1.0,
                    fontSize: 18.0,
                    onPressed: () async {
                               TextToSpeech.speak('Send Innvitation');

                    },
                    onDoubleTap: () async{
    if (_formKey.currentState!.validate() && _selectedRole != null) {
                        String email = _emailAddressTextController.text.trim();
                        String role = _selectedRole!;
                        String deviceId = widget.deviceId;
                        String senderEmail = FirebaseAuth.instance.currentUser!.email!; // Dynamically get the logged-in user's email

                        try {
                          // Check if the user exists in Firestore
                          var userQuery = await FirebaseFirestore.instance
                              .collection('users')
                              .where('email', isEqualTo: email)
                              .get();

                          if (userQuery.docs.isNotEmpty) {
                            // User exists, directly assign device to them
                            String recipientId = userQuery.docs.first.id;

                            await FirebaseFirestore.instance.collection('users').doc(recipientId).update({
                              'devices': FieldValue.arrayUnion([{'deviceId': deviceId, 'role': role}])
                            });
                          } else {
                            // User doesn't exist, store invitation in Firestore
                            await FirebaseFirestore.instance.collection('invitations').add({
                              'email': email,
                              'deviceId': deviceId,
                              'role': role,
                              'invitedBy': senderEmail, // Store the sender's email (dynamically fetched)
                              'status': 'pending',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          }

                          // Send email invitation dynamically using the logged-in user's email
                          await sendInvitation(senderEmail, email, role, deviceId);

                          // Navigate to profile page or another screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send invitation: $e')),
                          );
                                          TextToSpeech.speak('Failed to send invitation: $e');

                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an email and select a role')),
                        );
                                        TextToSpeech.speak('Please enter an email and select a role');

                      } // Double tap action
                               TextToSpeech.speak('Sending Invitation Back to Settings');
  },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(BuildContext context, String role, bool isSelected, VoidCallback onTap, double width, double height) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width, // Match the width of the text field
        height: height, // Fixed height
        decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 3,
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0.0, 1),
            )
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  role,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            Switch(
              value: isSelected,
              onChanged: (newValue) {
                setState(() {
                  _selectedRole = newValue ? role : null; // Allow only one switch to be active
                });
              },
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey,
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
