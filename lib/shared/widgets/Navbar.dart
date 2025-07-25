import 'dart:async';

import 'package:flutter/material.dart';

// Project imports
import '../services/TextToSpeech.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavbar({super.key, 
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Get the width of the screen
    final double screenWidth = MediaQuery.of(context).size.width;
  Timer? tapTimer; // Timer to detect single taps and delay the action

    // Calculate responsive icon size based on the screen width
    final double iconSize = screenWidth * 0.07;

    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () {
                      tapTimer?.cancel();

              // Announce the tap action for Profile
              TextToSpeech.speak('Profile tap');
              //onItemTapped(0);
               tapTimer = Timer(const Duration(milliseconds: 300), () {
          // Do something if no double-tap is detected within 300ms
          // This prevents navigation on single tap
        });
            },
            onDoubleTap: () {
                                    tapTimer?.cancel();

              TextToSpeech.speak('Profile screen');
              // Navigate to Profile screen on double tap
              onItemTapped(0);
            },
            child: Icon(
              Icons.person_2_outlined,
              size: iconSize,
            ),
          ),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () {
              tapTimer?.cancel();
              // Announce the tap action for Add Device
              TextToSpeech.speak('Add Device tap');
              tapTimer = Timer(const Duration(milliseconds: 300), () {
                // Prevents navigation on single tap
              });
            },
            onDoubleTap: () {
              tapTimer?.cancel();
              TextToSpeech.speak('Add Device screen');
              onItemTapped(1); // Add Device is index 1
            },
            child: Icon(
              Icons.add,
              size: iconSize,
            ),
          ),
          label: 'Add Device',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () {
              tapTimer?.cancel();
              // Announce the tap action for Notifications
              TextToSpeech.speak('Notifications tap');
              tapTimer = Timer(const Duration(milliseconds: 300), () {
                // Prevents navigation on single tap
              });
            },
            onDoubleTap: () {
              tapTimer?.cancel();
              TextToSpeech.speak('Notifications screen');
              onItemTapped(2); // Notifications is index 2
            },
            child: Icon(
              Icons.notifications_none,
              size: iconSize,
            ),
          ),
          label: 'Notifications',
        ),
      ],
      currentIndex: selectedIndex,
      unselectedItemColor: Colors.blueGrey,
      onTap: onItemTapped,
    );
  }
}
