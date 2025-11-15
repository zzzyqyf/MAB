import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
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
  Box? notificationsBox;
  int _selectedIndex = 2; // Notifications page is index 2
  Stream<QuerySnapshot>? _alarmStream;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  void _initializePage() {
    // Synchronously try to get the box if it's already open
    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        notificationsBox = Hive.box('notificationsBox');
      }
    } catch (e) {
      debugPrint('⚠️ Error accessing Hive box: $e');
    }

    // Initialize Firestore stream (non-blocking)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _alarmStream = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots();
      }
    } catch (e) {
      debugPrint('⚠️ Error initializing Firestore stream: $e');
    }
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

  // Clear all notifications
  Future<void> _clearAllNotifications() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notificationsBox?.clear();
      TextToSpeech.speak('All notifications cleared.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Dismiss individual notification
  Future<void> _dismissNotification(int index, bool isAlarm, String? docId) async {
    if (isAlarm && docId != null) {
      // Dismiss alarm notification in Firestore
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc(docId)
              .delete();
          
          TextToSpeech.speak('Alarm notification dismissed.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alarm notification dismissed'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error dismissing alarm notification: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to dismiss notification'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Dismiss local notification from Hive
      try {
        if (notificationsBox != null && index < notificationsBox!.length) {
          await notificationsBox!.deleteAt(index);
          TextToSpeech.speak('Notification dismissed.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification dismissed'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error dismissing local notification: $e');
      }
    }
  }

  // Get alarm notifications stream from Firestore
  Stream<QuerySnapshot>? _getAlarmNotificationsStream() {
    return _alarmStream; // Return cached stream
  }

  // Convert local Hive notifications to standard format
  List<Map<String, dynamic>> _getLocalNotifications(Box box) {
    final List<Map<String, dynamic>> notifications = [];
    for (int i = 0; i < box.length; i++) {
      try {
        final notification = box.getAt(i);
        if (notification == null) continue;
        
        notifications.add({
          'title': notification['title'] ?? 'Notification',
          'message': notification['message'] ?? '',
          'timestamp': DateTime.parse(notification['timestamp']),
          'isAlarm': false,
          'status': 'active',
          'index': i, // Include index for dismiss
        });
      } catch (e) {
        debugPrint('⚠️ Error parsing local notification at index $i: $e');
        // Skip malformed notifications
        continue;
      }
    }
    return notifications;
  }

  // Convert Firestore alarm notifications to standard format
  List<Map<String, dynamic>> _getAlarmNotifications(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> notifications = [];
    
    for (var doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        notifications.add({
          'title': '🚨 Alarm: ${data['reason'] ?? 'Critical Alert'}',
          'message': 'Device: ${data['deviceName'] ?? data['deviceId'] ?? 'Unknown'}',
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
          'isAlarm': true,
          'status': data['status'] ?? 'active',
          'docId': doc.id, // Include document ID for dismiss
        });
      } catch (e) {
        debugPrint('⚠️ Error parsing Firestore notification ${doc.id}: $e');
        // Skip malformed notifications
        continue;
      }
    }
    
    return notifications;
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF14181B)),
            onPressed: () {
              // Navigate back to main Dashboard page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage(title: 'PlantCare Hubs')),
              );
            },
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Color(0xFF14181B),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            if (notificationsBox != null)
              ValueListenableBuilder(
                valueListenable: notificationsBox!.listenable(),
                builder: (context, Box box, _) {
                  if (box.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    tooltip: 'Clear all notifications',
                    onPressed: _clearAllNotifications,
                  );
                },
              ),
          ],
          elevation: 0,
          centerTitle: false,
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getAlarmNotificationsStream(),
            builder: (context, alarmSnapshot) {
              // Handle Firestore errors gracefully
              if (alarmSnapshot.hasError) {
                debugPrint('⚠️ Firestore stream error: ${alarmSnapshot.error}');
                // Continue with local notifications only
              }
              
              // Show loading indicator only on first load
              if (alarmSnapshot.connectionState == ConnectionState.waiting && 
                  !alarmSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              // Handle case where Hive box is not available
              if (notificationsBox == null) {
                final alarmNotifications = (alarmSnapshot.hasData && !alarmSnapshot.hasError)
                    ? _getAlarmNotifications(alarmSnapshot.data!)
                    : <Map<String, dynamic>>[];
                
                if (alarmNotifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications available.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: alarmNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = alarmNotifications[index];
                    return buildNotificationCard(
                      notification['title'] as String,
                      notification['message'] as String,
                      formatTimestamp(notification['timestamp'] as DateTime),
                      isAlarm: notification['isAlarm'] == true,
                      status: notification['status'] as String?,
                      onDismiss: () => _dismissNotification(
                        0,
                        true,
                        notification['docId'] as String?,
                      ),
                    );
                  },
                );
              }
              
              return ValueListenableBuilder(
                valueListenable: notificationsBox!.listenable(),
                builder: (context, Box box, _) {
                  final localNotifications = _getLocalNotifications(box);
                  final alarmNotifications = (alarmSnapshot.hasData && !alarmSnapshot.hasError)
                      ? _getAlarmNotifications(alarmSnapshot.data!)
                      : <Map<String, dynamic>>[];
                  
                  // Combine and sort all notifications by timestamp
                  final allNotifications = [...localNotifications, ...alarmNotifications];
                  allNotifications.sort((a, b) {
                    final aTime = a['timestamp'] as DateTime;
                    final bTime = b['timestamp'] as DateTime;
                    return bTime.compareTo(aTime); // Newest first
                  });

                  if (allNotifications.isEmpty) {
                    // Defer TTS to avoid blocking UI during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        TextToSpeech.speak('No notifications available.');
                      }
                    });
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No notifications available.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: allNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = allNotifications[index];
                      return buildNotificationCard(
                        notification['title'] as String,
                        notification['message'] as String,
                        formatTimestamp(notification['timestamp'] as DateTime),
                        isAlarm: notification['isAlarm'] == true,
                        status: notification['status'] as String?,
                        onDismiss: () => _dismissNotification(
                          notification['index'] as int? ?? 0,
                          notification['isAlarm'] == true,
                          notification['docId'] as String?,
                        ),
                      );
                    },
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
  Widget buildNotificationCard(
    String title,
    String subtitle,
    String time, {
    bool isAlarm = false,
    String? status,
    VoidCallback? onDismiss,
  }) {
    // Determine background color and icon based on type and status
    Color backgroundColor = Colors.white;
    IconData icon = Icons.info_outline;
    Color iconColor = Colors.blue;

    if (isAlarm) {
      icon = Icons.alarm;
      if (status == 'dismissed') {
        backgroundColor = Colors.grey.shade100;
        iconColor = Colors.grey;
      } else if (status == 'snoozed') {
        backgroundColor = Colors.orange.shade50;
        iconColor = Colors.orange;
      } else {
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 1),
      child: InkWell(
        onTap: () {
          // Trigger Text-to-Speech when tapped
          String statusText = status != null && status != 'active' ? ' Status: $status.' : '';
          TextToSpeech.speak('$title. $subtitle.$statusText Received $time.');
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: const [
              BoxShadow(
                blurRadius: 0,
                color: Color(0xFFE0E3E7),
                offset: Offset(0, 1),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (isAlarm) ...[
                  Icon(icon, color: iconColor, size: 32),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: const Color(0xFF14181B),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          decoration: status == 'dismissed'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF57636C),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (status != null && status != 'active') ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            status == 'dismissed'
                                ? '✓ Dismissed'
                                : status == 'snoozed'
                                    ? '⏰ Snoozed'
                                    : status.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: status == 'dismissed'
                                  ? Colors.grey
                                  : Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xFF57636C),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (onDismiss != null && status != 'dismissed') ...[
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.red,
                        tooltip: 'Dismiss',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          onDismiss();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Format timestamp to a user-friendly display
  String formatTimestamp(DateTime dateTime) {
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
