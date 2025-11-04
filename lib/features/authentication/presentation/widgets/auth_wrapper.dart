import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Feature imports
import '../pages/signIn.dart';
import '../../../../main.dart';

/// AuthWrapper checks if user is authenticated and routes accordingly
/// This should be the root widget after MaterialApp
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is logged in, show the main app
        if (snapshot.hasData && snapshot.data != null) {
          return const MyHomePage(title: 'PlantCare Hubs');
        }
        
        // If user is not logged in, show login page
        return const LoginWidget();
      },
    );
  }
}
