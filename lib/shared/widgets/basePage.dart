import 'package:flutter/material.dart';
import '../services/TextToSpeech.dart'; // Import your TTS class

class BasePage extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed; // Custom back action

  const BasePage({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
  }) : super(key: key);

  void _handleBackNavigation(BuildContext context) {
    if (onBackPressed != null) {
      // Use custom back action if provided
      onBackPressed!();
    } else if (Navigator.canPop(context)) {
      // If there's a previous route, pop it
      Navigator.pop(context);
    } else {
      // If no previous route and no custom action, do nothing to prevent crash
      TextToSpeech.speak('Already at main screen');
    }
  }

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
          _handleBackNavigation(context);
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
                  _handleBackNavigation(context);
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
