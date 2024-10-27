import 'package:flutter/material.dart';
import 'package:flutter_application_final/ProfilePage.dart';
import 'basePage.dart';
import 'buttom.dart';

class EditUserWidget extends StatefulWidget {
  const EditUserWidget({Key? key}) : super(key: key);

  @override
  State<EditUserWidget> createState() => _EditUserWidgetState();
}

class _EditUserWidgetState extends State<EditUserWidget> with TickerProviderStateMixin {
  late TextEditingController _passwordCreateController;
  late TextEditingController _oldPasswordController;
  //bool _passwordCreateVisibility = false;
  bool _oldPasswordVisibility = false;

  @override
  void initState() {
    super.initState();
    _passwordCreateController = TextEditingController();
    _oldPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordCreateController.dispose();
    _oldPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04; // 4% of screen width
    final double fontSize = screenSize.width * 0.04; // Responsive font size for labels

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: BasePage(
          title: 'Edit Profile',
          showBackButton: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReusableTextField(
                    label: 'Name',
                    obscureText: false,
                    padding: padding,
                    fontSize: fontSize,
                  ),
                  
                 // SizedBox(height: padding),
                  ReusableTextField(
                    label: 'Email',
                    obscureText: false,
                    padding: padding,
                    fontSize: fontSize,
                  ),
                 // SizedBox(height: padding),
                  ReusableTextField(
                    label: 'Type the old Password',
                    controller: _oldPasswordController,
                    obscureText: !_oldPasswordVisibility,
                    onToggleVisibility: () {
                      setState(() {
                        _oldPasswordVisibility = !_oldPasswordVisibility;
                      });
                    },
                    isPassword: true,
                    padding: padding,
                    fontSize: fontSize,
                  ),
                  ReusableTextField(
                    label: 'Type the new Password',
                    controller: _oldPasswordController,
                    obscureText: !_oldPasswordVisibility,
                    onToggleVisibility: () {
                      setState(() {
                        _oldPasswordVisibility = !_oldPasswordVisibility;
                      });
                    },
                    isPassword: true,
                    padding: padding,
                    fontSize: fontSize,
                  ),
                //  SizedBox(height: padding),
                ],
              ),
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
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
                      },
      ),
      ),
    );
  }
}

class ReusableTextField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController? controller;
  final VoidCallback? onToggleVisibility;
  final bool isPassword;
  final double padding;
  final double fontSize;

  const ReusableTextField({
    Key? key,
    required this.label,
    this.obscureText = false,
    this.controller,
    this.onToggleVisibility,
    this.isPassword = false,
    required this.padding,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding / 2), // Responsive vertical padding
      child: TextFormField(
        controller: controller,
        autofocus: false,
        obscureText: obscureText,
        style: TextStyle(fontSize: fontSize), // Responsive text style
        decoration: InputDecoration(
                                labelText: label,
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
                                 suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
                                
                              ),
      ),
    );
  }
}
