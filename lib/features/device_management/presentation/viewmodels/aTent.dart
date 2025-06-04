/*import 'package:flutter/material.dart';
import 'mqttservice.dart'; // Import the MqttService class

class Register4 extends StatefulWidget {
  @override
  _Register4State createState() => _Register4State();
}

class _Register4State extends State<Register4> {
  double? temperature;
  double? humidity;
  int? lightState;

  late MqttService mqttService;

  @override
  void initState() {
    super.initState();
    mqttService = MqttService(onDataReceived: (temp, hum, light) {
      // When new data is received, update the UI using setState
      setState(() {
        temperature = temp;
        humidity = hum;
        lightState = light;
      });
    });
    mqttService.setupMqttClient(); // Setup the MQTT client on widget initialization
  }

  @override
  void dispose() {
    mqttService.dispose(); // Clean up the MQTT connection when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ESP32 Control & Monitor')),
      body: Column(
        children: [
          Text('Temperature: ${temperature ?? 'Loading...'} °C'),
          Text('Humidity: ${humidity ?? 'Loading...'} %'),
          Text('Light State: ${lightState == 1 ? 'High' : 'Low'}'),

          // Toggle LEDs
          ElevatedButton(
            onPressed: () => mqttService.sendMessage("LED_ON"),
            child: Text("Turn LED On"),
          ),
          ElevatedButton(
            onPressed: () => mqttService.sendMessage("LED_OFF"),
            child: Text("Turn LED Off"),
          ),
        ],
      ),
    );
  }
}
*/