import 'package:flutter/material.dart';

// Project imports
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/Navbar.dart';
import '../../../profile/presentation/pages/ProfilePage.dart';
import '../../../notifications/presentation/pages/notification.dart';

class addPage extends StatefulWidget {
  const addPage({Key? key}) : super(key: key);

  @override
  State<addPage> createState() => _AddPageState();
}

class _AddPageState extends State<addPage> {
  int _selectedIndex = 1; // Add page is index 1

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to Profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
      case 1:
        // Already on Add page, do nothing
        break;
      case 2:
        // Navigate to Notifications page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasePage(
        title: 'Add Device',
        showBackButton: true,
      ),
      body: const Center(
        child: Text(
          'Add Device Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

