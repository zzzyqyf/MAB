import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/Navbar.dart';
import '../../../profile/presentation/pages/ProfilePage.dart';
import '../../../registration/presentation/pages/registerOne.dart';
import '../../../../main.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late Box notificationsBox;
  int _selectedIndex = 2; // Notifications page is index 2

  @override
  void initState() {
    notificationsBox = Hive.box('notificationsBox'); // Access the Hive notifications box
    super.initState();
  }

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
        // Navigate to Add Device page (Registration)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Register2Widget()),
        );
        break;
      case 2:
        // Already on Notifications page, do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: BasePage(
          title: 'Notifications',
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
          child: ValueListenableBuilder(
            valueListenable: notificationsBox.listenable(),
            builder: (context, Box box, _) {
              if (box.isEmpty) {
                TextToSpeech.speak('No notifications available.');
                return const Center(child: Text('No notifications available.'));
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: box.length,
                itemBuilder: (context, index) {
                  final notification = box.getAt(index);
                  return buildNotificationCard(
                    notification['title'],    // Title from Hive
                    notification['message'],  // Message from Hive
                    formatTimestamp(notification['timestamp']), // Timestamp
                  );
                },
              );
            },
          ),
        ),
        bottomNavigationBar: CustomNavbar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }

  // Reusable notification card widget
  Widget buildNotificationCard(String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 1),
      child: InkWell(
        onTap: () {
          // Trigger Text-to-Speech when tapped
          TextToSpeech.speak('$title. $subtitle. Received $time.');
        },
        child: Container(
          width: double.infinity,
          height: 91,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 0,
                color: Color(0xFFE0E3E7),
                offset: Offset(0, 1),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Color(0xFF14181B),
                          fontSize: 23,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF57636C),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFF57636C),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Format timestamp to a user-friendly display
  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
