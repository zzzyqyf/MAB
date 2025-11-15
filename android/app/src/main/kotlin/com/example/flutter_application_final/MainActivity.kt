package com.example.flutter_application_final

import android.media.ToneGenerator
import android.media.AudioManager
import android.media.AudioFocusRequest
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.media.Ringtone
import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "alarm_channel"
    private var toneGenerator: ToneGenerator? = null
    private var ringtone: Ringtone? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var hasAudioFocus = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        // Request audio focus for alarm playback
        requestAudioFocusForAlarm()
        
        // Initialize ToneGenerator with maximum volume
        toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, ToneGenerator.MAX_VOLUME)
        
        // Get the default alarm sound
        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        ringtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playBeep" -> {
                    try {
                        Log.d("AlarmService", "========== PLAYBEEP CALLED ==========")
                        
                        // ⚡ CRITICAL: Re-request audio focus before EVERY beep
                        if (!hasAudioFocus) {
                            Log.w("AlarmService", "⚠️ No audio focus - requesting now...")
                            requestAudioFocusForAlarm()
                        } else {
                            Log.d("AlarmService", "✅ Already have audio focus")
                        }
                        
                        // Get current alarm volume
                        val currentVolume = audioManager?.getStreamVolume(AudioManager.STREAM_ALARM) ?: 0
                        val maxVolume = audioManager?.getStreamMaxVolume(AudioManager.STREAM_ALARM) ?: 0
                        
                        Log.d("AlarmService", "Alarm volume: $currentVolume / $maxVolume")
                        
                        if (currentVolume == 0) {
                            Log.e("AlarmService", "❌ ALARM VOLUME IS MUTED! User won't hear anything!")
                        } else if (currentVolume < maxVolume / 4) {
                            Log.w("AlarmService", "⚠️ Alarm volume is low: $currentVolume / $maxVolume")
                        } else {
                            Log.i("AlarmService", "✅ Alarm volume OK: $currentVolume / $maxVolume")
                        }
                        
                        // Check if ToneGenerator is initialized
                        if (toneGenerator == null) {
                            Log.e("AlarmService", "❌ ToneGenerator is NULL! Recreating...")
                            toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, ToneGenerator.MAX_VOLUME)
                        }
                        
                        // Method 1: ToneGenerator (primary)
                        try {
                            Log.d("AlarmService", "🔊 Playing ToneGenerator beep...")
                            val toneResult = toneGenerator?.startTone(
                                ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK, 
                                500
                            )
                            Log.d("AlarmService", "ToneGenerator.startTone() returned: $toneResult")
                            
                            if (toneResult == true) {
                                Log.i("AlarmService", "✅ ToneGenerator beep playing")
                            } else {
                                Log.e("AlarmService", "❌ ToneGenerator.startTone() returned false")
                            }
                            
                            // Keep tone playing
                            Thread.sleep(500)
                            
                        } catch (e: Exception) {
                            Log.e("AlarmService", "❌ ToneGenerator FAILED: ${e.message}")
                            Log.e("AlarmService", "Stack: ${e.stackTraceToString()}")
                        }
                        
                        // Method 2: Vibration (always do this)
                        try {
                            Log.d("AlarmService", "📳 Triggering vibration...")
                            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                                vibratorManager.defaultVibrator
                            } else {
                                @Suppress("DEPRECATION")
                                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                            }
                            
                            if (vibrator.hasVibrator()) {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 200, 100, 200), -1))
                                } else {
                                    @Suppress("DEPRECATION")
                                    vibrator.vibrate(longArrayOf(0, 200, 100, 200), -1)
                                }
                                Log.i("AlarmService", "✅ Vibration triggered")
                            } else {
                                Log.w("AlarmService", "⚠️ Device has no vibrator")
                            }
                        } catch (e: Exception) {
                            Log.e("AlarmService", "❌ Vibration FAILED: ${e.message}")
                        }
                        
                        Log.d("AlarmService", "========== PLAYBEEP COMPLETE ==========")
                        
                        result.success(mapOf(
                            "volume" to currentVolume,
                            "maxVolume" to maxVolume,
                            "success" to true
                        ))
                    } catch (e: Exception) {
                        Log.e("AlarmService", "❌❌❌ CRITICAL playBeep error: ${e.message}")
                        Log.e("AlarmService", "Stack: ${e.stackTraceToString()}")
                        result.error("BEEP_ERROR", "Failed to play beep: ${e.message}", e.stackTraceToString())
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Request audio focus for alarm playback
     * This is CRITICAL for devices like MIUI, Huawei, Vivo, etc.
     */
    private fun requestAudioFocusForAlarm() {
        audioManager?.let { manager ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 8.0+ - Use AudioFocusRequest
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                
                audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(audioAttributes)
                    .setWillPauseWhenDucked(false)
                    .setAcceptsDelayedFocusGain(false)
                    .setOnAudioFocusChangeListener { focusChange ->
                        when (focusChange) {
                            AudioManager.AUDIOFOCUS_GAIN -> {
                                Log.d("AlarmService", "✅ Audio focus GAINED")
                                hasAudioFocus = true
                            }
                            AudioManager.AUDIOFOCUS_LOSS -> {
                                Log.w("AlarmService", "⚠️ Audio focus LOST")
                                hasAudioFocus = false
                            }
                            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                                Log.w("AlarmService", "⚠️ Audio focus lost temporarily")
                            }
                            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                                Log.i("AlarmService", "ℹ️ Audio focus lost (can duck)")
                            }
                        }
                    }
                    .build()
                
                val result = manager.requestAudioFocus(audioFocusRequest!!)
                hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
                Log.d("AlarmService", "🔊 Audio focus request result: ${if (hasAudioFocus) "GRANTED ✅" else "DENIED ❌"}")
                
            } else {
                // Android 7.1 and below - Use legacy API
                @Suppress("DEPRECATION")
                val result = manager.requestAudioFocus(
                    { focusChange ->
                        when (focusChange) {
                            AudioManager.AUDIOFOCUS_GAIN -> {
                                Log.d("AlarmService", "✅ Audio focus GAINED (legacy)")
                                hasAudioFocus = true
                            }
                            AudioManager.AUDIOFOCUS_LOSS -> {
                                Log.w("AlarmService", "⚠️ Audio focus LOST (legacy)")
                                hasAudioFocus = false
                            }
                        }
                    },
                    AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
                )
                hasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
                Log.d("AlarmService", "🔊 Audio focus request (legacy) result: ${if (hasAudioFocus) "GRANTED ✅" else "DENIED ❌"}")
            }
        }
    }

    override fun onDestroy() {
        // Release audio focus
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { request ->
                audioManager?.abandonAudioFocusRequest(request)
                Log.d("AlarmService", "🔇 Audio focus released")
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(null)
        }
        
        toneGenerator?.release()
        toneGenerator = null
        ringtone?.stop()
        ringtone = null
        super.onDestroy()
    }
}
