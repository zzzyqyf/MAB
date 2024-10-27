import 'package:flutter/material.dart';

import 'basePage.dart';

class MemberListWidget extends StatefulWidget {
  const MemberListWidget({Key? key}) : super(key: key);

  @override
  State<MemberListWidget> createState() => _MemberListWidgetState();
}

class _MemberListWidgetState extends State<MemberListWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _switchValue = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color.fromARGB(255, 18, 108, 210), // Dark cyan-purple blend

         appBar: BasePage(
          title: 'Members',
          showBackButton: true,
        ),
        body:  Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 6, 94, 135), // Dark cyan-purple blend
              Color.fromARGB(255, 84, 90, 95), // Complementary color
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            TabBar(
              labelColor: const Color.fromARGB(255, 232, 230, 230),
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                letterSpacing: 0.0,
              ),
              indicatorColor: Colors.grey[200],
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Inactive'),
              ],
              controller: _tabController,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMemberList(context, true),
                  _buildMemberList(context, false),
                ],
              ),
            ),
          ],
        ),
     
       ) ),
    );
    
    
  }

  Widget _buildMemberList(BuildContext context, bool isActive) {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                    color: Theme.of(context).secondaryHeaderColor,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0.0, 1),
                  )
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Member Name',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.black,
                                fontSize: 20,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text(
                              isActive ? 'Admin' : 'Inactive',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.black,
                                fontSize: 20,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Switch.adaptive(
                        value: _switchValue,
                        onChanged: (newValue) {
                          setState(() {
                            _switchValue = newValue;
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
          ),
        ],
      ),
    );
  }
}
