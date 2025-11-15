import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

class TextToSpeech {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;

  /// Initialize TTS with proper audio configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🗣️ Initializing TTS...');
      
      // Add timeout to prevent blocking app startup
      await Future.any([
        _initializeTTS(),
        Future.delayed(const Duration(seconds: 3)).then((_) {
          debugPrint('⚠️ TTS initialization timeout - continuing anyway');
          throw TimeoutException('TTS initialization timed out');
        }),
      ]);
      
      _isInitialized = true;
      debugPrint('✅ TTS initialized successfully');
    } catch (e) {
      debugPrint('❌ TTS initialization failed: $e');
      // Mark as initialized anyway to prevent retry loops
      _isInitialized = true;
    }
  }

  /// Internal TTS initialization method
  static Future<void> _initializeTTS() async {
    // Platform-specific configuration
    if (Platform.isAndroid) {
      // Android: Use media stream and request audio focus
      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(false); // Don't block
      
      // Set audio category (if supported) - skip iOS-specific settings on Android
      debugPrint('ℹ️ Skipping iOS audio category on Android');
    } else if (Platform.isIOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    }
    
    // Common settings
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0); // Maximum volume
  }

  static Future<void> speak(String message) async {
    // Ensure TTS is initialized
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _tts.speak(message);
    } catch (e) {
      debugPrint('❌ TTS speak failed: $e');
    }
  }
}