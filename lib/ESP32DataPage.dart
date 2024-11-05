import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ESP32DataPage extends StatefulWidget {
  @override
  _ESP32DataPageState createState() => _ESP32DataPageState();
}

class _ESP32DataPageState extends State<ESP32DataPage> {
  final FlutterTts flutterTts = FlutterTts();
  String esp32Data = "Waiting for data...";  // Initial placeholder

  // Method to speak the updated data
  void speakText(String text) async {
    await flutterTts.speak(text);
  }

  // Simulated method to handle ESP32 data update
  void onESP32DataUpdate(String newData) {
    setState(() {
      esp32Data = newData;  // Update with the latest data
    });
    speakText("Updated Data: $esp32Data");  // Read the updated data aloud
  }

  // Optional: Clean up resources when not needed
  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32 Data Page'),
      ),
      body: Center(
        child: Text(
          esp32Data,
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simulate receiving new data from ESP32; replace with actual data handling
          String simulatedData = "Temperature is 25 degrees Celsius";
          onESP32DataUpdate(simulatedData);
        },
        child: Icon(Icons.update),
      ),
    );
  }
}
