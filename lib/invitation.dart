import 'package:flutter/material.dart';
import 'ProfilePage.dart';
import 'basePage.dart';
import 'buttom.dart';

class InvitationWidget extends StatefulWidget {
  const InvitationWidget({super.key});

  @override
  State<InvitationWidget> createState() => _InvitationWidgetState();
}

class _InvitationWidgetState extends State<InvitationWidget> {
  final _emailAddressTextController = TextEditingController();
  final _emailAddressFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedRole; // To track the selected role

  @override
  void dispose() {
    _emailAddressTextController.dispose();
    _emailAddressFocusNode.dispose();
    super.dispose();
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
        appBar: BasePage(
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
                          /*
                          Text(
                            'Enter their email and choose a role',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                            ),
                            
                            textAlign: TextAlign.center, // Center text for better aesthetics
                          ),
                          */
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
        onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
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
