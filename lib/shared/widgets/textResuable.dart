import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool autofocus;

  const CustomTextField({
    Key? key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double fontSize = MediaQuery.of(context).size.width * 0.045; // Responsive font size

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        autofillHints: keyboardType == TextInputType.emailAddress
            ? [AutofillHints.email]
            : null,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
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
        validator: validator,
      ),
    );
  }
}
