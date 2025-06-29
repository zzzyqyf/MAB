import 'package:flutter/material.dart';
import '../../../shared/services/TextToSpeech.dart'; // Import TTS for consistency

/// Reusable AppBar component for graph screens
/// Provides consistent styling and behavior across all graph types
/// Matches BasePage design with accessibility features
class GraphAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String deviceId;
  final bool isDeviceActive;
  final String title;
  final bool showBackButton;

  const GraphAppBar({
    super.key,
    required this.deviceId,
    required this.isDeviceActive,
    this.title = 'Graph',
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final displayTitle = '${isDeviceActive ? "Device Active" : "Device Inactive"} - $deviceId';

    return GestureDetector(
      onTap: () {
        // Single tap triggers Text-to-Speech for the title (consistent with BasePage)
        TextToSpeech.speak(displayTitle);
      },
      onDoubleTap: () {
        // Double tap retains the existing behavior (consistent with BasePage)
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
                  size: screenWidth * 0.06, // Responsive icon size (consistent with BasePage)
                ),
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
              )
            : null,
        title: Text(
          displayTitle,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: screenWidth * 0.05, // Responsive text size (consistent with BasePage)
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
