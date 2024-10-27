import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';


void main() {
  runApp(
    DevicePreview(
      enabled: true, // Enable the device preview
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true, // Enable media query for responsiveness
      builder: DevicePreview.appBuilder, // Wraps the app with DevicePreview
      locale: DevicePreview.locale(context), // Supports locale changes in DevicePreview
      title: 'Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
    home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //int _selectedIndex = 0; // Track the selected index

  // Define pages to navigate to
  

  

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context); // Get screen dimensions

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: const AlignmentDirectional(0, -1),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                0, 
                mediaQuery.size.height * 0.05, // Responsive top padding
                0, 
                0
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tent',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: mediaQuery.size.width * 0.08, // Responsive font size
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0, mediaQuery.size.height * 0.15, 0, 50),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, mediaQuery.size.height * 0.02, 0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: mediaQuery.size.width * 0.4, // Responsive container width
                        height: mediaQuery.size.width * 0.4, // Responsive container height
                        decoration: BoxDecoration(
                          color: const Color(0xFF4E5077),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const AlignmentDirectional(-0.09, -0.14),
                              child: Text(
                                'TENTNAME',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontSize: mediaQuery.size.width * 0.06, // Responsive font size
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(-0.15, 0.63),
                              child: Text(
                                'Critical',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontSize: mediaQuery.size.width * 0.06, // Responsive font size
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(0.82, -0.8),
                              child: Icon(
                                Icons.wifi_off,
                                color:Colors.red,
                                size: mediaQuery.size.width * 0.09, // Responsive icon size
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: mediaQuery.size.width * 0.05), // Responsive space between widgets
                      Container(
                        width: mediaQuery.size.width * 0.4, // Responsive container width
                        height: mediaQuery.size.width * 0.4, // Responsive container height
                        decoration: BoxDecoration(
                          color: const Color(0xFF4E5077),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const AlignmentDirectional(-0.09, -0.14),
                              child: Text(
                                'TentName',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontSize: mediaQuery.size.width * 0.06, // Responsive font size
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(-0.15, 0.63),
                              child: Text(
                                'Critical',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontSize: mediaQuery.size.width * 0.06, // Responsive font size
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(0.82, -0.8),
                              child: Icon(
                                Icons.wifi_outlined,
                                color: Colors.green,
                                size: mediaQuery.size.width * 0.09, // Responsive icon size
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, mediaQuery.size.height * 0.02, 0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: mediaQuery.size.width * 0.4, // Responsive container width
                        height: mediaQuery.size.width * 0.4, // Responsive container height
                        decoration: BoxDecoration(
                          color: const Color(0xFF4E5077),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const AlignmentDirectional(-0.09, -0.14),
                              child: Text(
                                'TENTNAME',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontSize: mediaQuery.size.width * 0.06, // Responsive font size
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(-0.15, 0.63),
                              child: Text(
                                'Critical',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontSize: mediaQuery.size.width * 0.06, // Responsive font size
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(0.82, -0.8),
                              child: Icon(
                                Icons.wifi_off,
                                color:Colors.red,
                                size: mediaQuery.size.width * 0.09, // Responsive icon size
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: mediaQuery.size.width * 0.05), // Responsive space between widgets
                      Container(
                        width: mediaQuery.size.width * 0.4, // Responsive container width
                        height: mediaQuery.size.width * 0.4, // Responsive container height
                        decoration: BoxDecoration(
                          color: const Color(0xFF4E5077),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const AlignmentDirectional(-0.09, -0.14),
                              child: Text(
                                'TentName',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontSize: mediaQuery.size.width * 0.06, // Responsive font size
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(-0.15, 0.63),
                              child: Text(
                                'Critical',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  fontSize: mediaQuery.size.width * 0.06, // Responsive font size
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(0.82, -0.8),
                              child: Icon(
                                Icons.wifi_outlined,
                                color: Colors.green,
                                size: mediaQuery.size.width * 0.09, // Responsive icon size
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
    );
  }
}
