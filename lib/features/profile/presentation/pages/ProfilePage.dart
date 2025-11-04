import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../authentication/presentation/pages/signIn.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/Navbar.dart';
import '../../../notifications/presentation/pages/notification.dart';
import '../../../registration/presentation/pages/registerOne.dart';
import '../../../../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfilePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // Profile page is index 0
  User? currentUser;
  String userEmail = '';
  String userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        userEmail = currentUser!.email ?? 'No email';
        // Extract username from email (part before @)
        userName = userEmail.split('@').first;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Show loading indicator
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        // Close loading dialog
        if (!mounted) return;
        Navigator.of(context).pop();

        TextToSpeech.speak('Logged out successfully');

        // The AuthWrapper will automatically redirect to login page
        // Navigate to login screen
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginWidget()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      TextToSpeech.speak('Logout failed');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Profile page, do nothing
        break;
      case 1:
        // Navigate to Add Device page (Registration)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Register2Widget()),
        );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenSize = MediaQuery.of(context).size;
    // Determine padding and sizing based on screen size
    /*
    final horizontalPadding = screenSize.width * 0.05;
    final containerHeight = screenSize.height * 0.1;
    final fontSizeTitle = screenSize.width * 0.05;
    final fontSizeSubtitle = screenSize.width * 0.04;
    final verticalSpacing = screenSize.height * 0.02;
    */
    final fontSizeTitle = screenSize.width * 0.05;


    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BasePage(
        title: 'Profile',
        showBackButton: true,
        onBackPressed: () {
          // Navigate back to main Dashboard page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage(title: 'PlantCare Hubs')),
          );
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),

          children: [
            // Profile Information
            Container(
              height: 85, // Set the fixed height of the box
              decoration: BoxDecoration(
                color: Theme.of(context).secondaryHeaderColor,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    color: Color.fromARGB(52, 2, 2, 2),
                    //offset: const Offset(0, 2),
                  ),
                ],
              ),
          child: IntrinsicHeight(
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName,
          style: TextStyle(
            fontSize: fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          userEmail,
          style: TextStyle(
            fontSize: fontSizeTitle * 0.8,
          ),
        ),
      ],
    ),
  ),
),
            ),
          //  const SizedBox(height: 10),
/*
            // Profile Options
            _buildProfileOption(
              context,
              title: 'Edit Profile',
              icon: Icons.account_circle_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditUserWidget()),
                );
              },
              screenWidth: screenWidth,
            ),
            const SizedBox(height: 6),

            _buildProfileOption(
              context,
              title: 'Invite',
              icon: Icons.inventory_sharp,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvitationWidget(deviceId: '',)),
                );
              },
              screenWidth: screenWidth,
            ),
                        const SizedBox(height: 6),

            _buildProfileOption(
              context,
              title: 'Invited Members',
              icon: Icons.people_alt_sharp,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MemberListWidget()),
                );
              },
              screenWidth: screenWidth,
            ),
                        const SizedBox(height: 6),
*/
                        const SizedBox(height: 6),

           _buildProfileOption(
  context,
  title: 'Logout',
  icon: Icons.logout_sharp,
  onTap: () {
    // Announce the tap action for Logout using TextToSpeech
    TextToSpeech.speak('Logout button');
  },
  onDoubleTap: () {
    // Trigger logout on double-tap
    _handleLogout();
  },
  screenWidth: screenWidth,
),

                        const SizedBox(height: 6),

          ],
        ),
      ),
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildProfileOption(
  BuildContext context, {
  required String title,
  required IconData icon,
  String? routeName,
  VoidCallback? onTap,
  VoidCallback? onDoubleTap,  // Added onDoubleTap parameter
  required double screenWidth,
}) {
  return InkWell(
    onTap: () {
      if (onTap != null) {
        onTap(); // Trigger onTap action
      } else if (routeName != null) {
        Navigator.pushNamed(context, routeName);
      }
    },
    onDoubleTap: onDoubleTap,  // Handle onDoubleTap action
    child: Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).secondaryHeaderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: screenWidth * 0.06,
              color: Theme.of(context).primaryColor), // Responsive icon size
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.05, // Responsive text size
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: screenWidth * 0.05,
              color: Colors.grey), // Responsive icon size
        ],
      ),
    ),
  );
}

}
