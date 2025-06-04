import 'package:flutter/material.dart';

// Project imports
import '../services/TextToSpeech.dart';
import '../../main.dart';
//import 'package:google_fonts/google_fonts.dart';

//import 'basePage.dart';
import 'buttom.dart';

class LoadingCopyWidget extends StatefulWidget {
  const LoadingCopyWidget({Key? key}) : super(key: key);

  @override
  State<LoadingCopyWidget> createState() => _LoadingCopyWidgetState();
}

class _LoadingCopyWidgetState extends State<LoadingCopyWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white, // Use your desired background color
        
        body: const SafeArea(
          top: true,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Align(
                      alignment: AlignmentDirectional(0, 1),
                      child: Padding(
                        padding: EdgeInsets.only(top: 200.0),
                        child: Text(
                          'Connected Successfully',
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
        bottomNavigationBar: ReusableBottomButton(
        buttonText: 'Ok',
        padding: 16.0,
        fontSize: 18.0,
        onPressed: () {
          TextToSpeech.speak('Save Button');

                      },
                      onDoubleTap: () {
    Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyApp()),
                ); // Double tap action
  },
      ),
      

      ),
    );
  }
}
