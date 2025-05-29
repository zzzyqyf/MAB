import 'package:flutter/material.dart';

class ReusableBottomButton extends StatelessWidget {
  final String buttonText;
  final double padding;
  final double fontSize;
  final VoidCallback onPressed;
  final VoidCallback onDoubleTap; // Added callback for double tap

   const ReusableBottomButton({
    Key? key,
    required this.buttonText,
    required this.padding,
    required this.fontSize,
    required this.onPressed,
    required this.onDoubleTap, // Initialize the double-tap callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: GestureDetector(
        onTap: onPressed,
        onDoubleTap: onDoubleTap, // Handle double-tap event
        child: Container(
          width: double.infinity, // Full width
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 6, 94, 135), // Dark cyan-purple blend
                Color.fromARGB(255, 84, 90, 95), // Complementary color
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0), // Adjust height
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
