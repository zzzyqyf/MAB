import 'package:flutter/material.dart';

import 'basePage.dart';

class time extends StatefulWidget {
  const time({Key? key}) : super(key: key);

  @override
  State<time> createState() => _SoundWidgetState();
}

class _SoundWidgetState extends State<time> {
  bool switchValue1 = true;  // Default value for the first switch
  bool switchValue2 = false; // Default value for the second switch
  bool switchValue3 = false; // Default value for the third switch

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
       appBar: const BasePage(
        title: 'Profile',
        showBackButton: true,
      ),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSoundOption('5 mintues', 1, switchValue1),
                    _buildSoundOption('30 mintues', 2, switchValue2),
                    _buildSoundOption('60 mintues', 3, switchValue3),
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundOption(String label, int index, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        width: double.infinity,
        height: 60, // Set height to make all boxes the same size
        decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
          boxShadow: const [
            BoxShadow(
              blurRadius: 3,
              color: Color(0x20000000),
              offset: Offset(0.0, 1),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  letterSpacing: 0.0,
                ),
              ),
              Switch.adaptive(
                value: isSelected,
                onChanged: (newValue) {
                  setState(() {
                    // Set all switches to false first
                    switchValue1 = false;
                    switchValue2 = false;
                    switchValue3 = false;

                    // Activate the selected switch
                    if (index == 1) {
                      switchValue1 = true;
                    } else if (index == 2) {
                      switchValue2 = true;
                    } else if (index == 3) {
                      switchValue3 = true;
                    }
                  });
                },
                activeColor: Colors.blue,
                activeTrackColor: Colors.blueAccent,
                inactiveTrackColor: Colors.grey,
                inactiveThumbColor: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
