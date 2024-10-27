import 'package:flutter/material.dart';

import 'basePage.dart';

class notification extends StatefulWidget {
  const notification({super.key});

  @override
  State<notification> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<notification> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: BasePage(
        title: 'Profile',
        showBackButton: true, 
      ),
        body: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  buildNotificationCard('TentName', 'high temperature', '2m ago'),
                  buildNotificationCard('TentName', 'high temperature', '2m ago'),
                  buildNotificationCard('TentName', 'high temperature', '2m ago'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNotificationCard(String title, String subtitle, String time) {
    

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 1),
     child: InkWell(
      onTap: () {
       
          Navigator.pushNamed(context, 'AnotherPage');
        } ,
      
      
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
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                  child: InkWell(
                    onTap: () {
                      // Handle navigation on tap
                      Navigator.pushNamed(context, 'Temperture');
                    },
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
}
