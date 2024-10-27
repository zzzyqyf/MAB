import 'package:flutter/material.dart';
import 'package:flutter_application_final/registerFour.dart';

import 'basePage.dart';
import 'buttom.dart';

class Register3Widget extends StatefulWidget {
  const Register3Widget({Key? key}) : super(key: key);

  @override
  State<Register3Widget> createState() => _Register3WidgetState();
}

class _Register3WidgetState extends State<Register3Widget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _isVisible = true; // Control animation visibility

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: BasePage(
        title: 'Wifi',
        showBackButton: true,
      ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Select a Wifi Network',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildAnimatedWifiTile('SmSWifi'),
                  _buildAnimatedWifiTile('HomeNetwork'),
                  _buildAnimatedWifiTile('GuestWifi'),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),

        bottomNavigationBar: ReusableBottomButton(
        buttonText: 'Next',
        padding: 16.0,
        fontSize: 18.0,
        onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Register4Widget()),
                );
                      },
      ),
      /*
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isVisible = !_isVisible; // Toggle visibility
            });
          },
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add),
        ),
        */
      ),
    );
  }

  Widget _buildAnimatedWifiTile(String wifiName) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(
        0, _isVisible ? 0 : 60, 0,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: _buildWifiTile(wifiName),
    );
  }

  Widget _buildWifiTile(String wifiName) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, 'register4');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              blurRadius: 2,
              color: Color(0xFFE0E3E7),
              offset: Offset(0, 1),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                wifiName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_right_rounded,
              color: Color(0xFF57636C),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  
}
