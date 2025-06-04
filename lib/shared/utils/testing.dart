import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TTS Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TextToSpeechExample(),
    );
  }
}

class TextToSpeechExample extends StatefulWidget {
  const TextToSpeechExample({super.key});

  @override
  _TextToSpeechExampleState createState() => _TextToSpeechExampleState();
}

class _TextToSpeechExampleState extends State<TextToSpeechExample> {
  final FlutterTts _flutterTts = FlutterTts();

  // Texts to be displayed and read aloud
  final List<String> _texts = [
    " 1 Welcome to the Flutter Text-to-Speech demo.",
    "This is normal text that will be read aloud when clicked.",
    "Flutter makes building apps easy and fun!",
  ];

  // Function to read the text aloud
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter TTS Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _texts
              .map(
                (text) => GestureDetector(
                  onTap: () => _speak(text), // When text is tapped, speak it
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
