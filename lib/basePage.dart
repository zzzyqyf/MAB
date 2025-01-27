import 'package:flutter/material.dart';
import 'package:flutter_application_final/TextToSpeech.dart'; // Import your TTS class

class BasePage extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const BasePage({
    Key? key,
    required this.title,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        // Single tap triggers Text-to-Speech for the title
        TextToSpeech.speak(title);
      },
      onDoubleTap: () {
        // Double tap retains the existing behavior
        if (showBackButton) {
          Navigator.pop(context); // Navigate back
        }
      },
      child: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).primaryColor,
                  size: screenWidth * 0.06, // Responsive icon size
                ),
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: screenWidth * 0.05, // Responsive text size
          ),
        ),
        elevation: 1,
        actions: const [
          // Add responsive actions if needed
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
