import 'package:flutter/material.dart';

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

    return AppBar(
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
