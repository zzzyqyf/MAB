import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> speak(String message) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5); // Adjust the speed for better clarity
    await _tts.speak(message);
  }
}
