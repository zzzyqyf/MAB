import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final List<Map<String, String>> devices; // List of devices passed from Register4Widget

  const DashboardPage({Key? key, required this.devices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connected Devices'),
      ),
      body: devices.isEmpty
          ? Center(child: Text('No devices added yet.'))
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return GestureDetector(
                  onTap: () {
                    // Handle tap (show detailed page or other actions)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Device ID: ${device['id']}')),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: ${device['id']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('Name: ${device['name']}'),
                          SizedBox(height: 8),
                          Text('Status: ${device['status']}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
