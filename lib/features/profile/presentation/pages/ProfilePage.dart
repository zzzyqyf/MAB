import 'package:flutter/material.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../authentication/presentation/pages/signIn.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/Navbar.dart';
import '../../../notifications/presentation/pages/notification.dart';
import '../../../registration/presentation/pages/registerOne.dart';
import '../../../../main.dart';
//import 'test.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfilePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // Profile page is index 0

  @override
  void initState() {
    super.initState();
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
          'zhang yifei',
          style: TextStyle(
            fontSize: fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'masalaysia@gmail.com',
          style: TextStyle(
            fontSize: fontSizeTitle,
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
    // Navigate to Login screen on double-tap
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginWidget()),
    );
        TextToSpeech.speak('Logged Out');

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
