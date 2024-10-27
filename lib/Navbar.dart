import 'package:flutter/material.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavbar({super.key, 
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
        //final screenWidth = MediaQuery.of(context).size.width;

    // Get the width of the screen
    final double screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive icon size based on the screen width
    final double iconSize = screenWidth * 0.07; // Use 8% of the screen width for icon size

    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person_2_outlined,
            size: iconSize,  
            // Responsive icon size
          ),
          label: 'Profile', // Always show label
        ),
        BottomNavigationBarItem(
          icon: Icon(
  Icons.notifications_none, // Outlined notification icon
            size: iconSize,  
          ),
          label: 'Notifications', // Always show label
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.add,
            size: iconSize,  
          ),
          label: 'Add', // Always show label
        ),
        
      ],
      currentIndex: selectedIndex,
     //selectedItemColor: Color.fromARGB(255, 144, 94, 153),
      unselectedItemColor: Colors.blueGrey,
      onTap: onItemTapped,
    );
  }
}
