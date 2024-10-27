import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';

//import 'basePage.dart';
import 'loadingT.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white, // Use your desired background color
       
        body: SafeArea(
          top: true,
          child: InkWell(
            onTap: () {
              // Navigate to another loading screen
 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoadingCopyWidget()),
                );            },
            child: const Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center, // Center the text
                    children: [
                      Align(
                        alignment: AlignmentDirectional(0, 1),
                        child: Padding(
                          padding: EdgeInsets.only(top: 200.0),
                          child: Text(
                            'Connecting to Wifi...',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.black, // Set your desired text color
                              fontSize: 20,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
