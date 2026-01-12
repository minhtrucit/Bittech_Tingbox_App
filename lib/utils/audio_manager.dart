import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  // Singleton instance
  static final AudioManager _instance = AudioManager._internal();

  factory AudioManager() {
    return _instance;
  }

  AudioManager._internal();

  // Audio Pool for scan sound
  AudioPool? _scanSoundPool;

  /// Initialize and preload audio files
  Future<void> init() async {
    try {
      // Create AudioPool for low latency playback
      _scanSoundPool = await FlameAudio.createPool(
        'scanner_audio.mp3',
        maxPlayers: 2,
      );
      debugPrint('✅ AudioManager: Audio pool initialized successfully');
    } catch (e) {
      debugPrint('❌ AudioManager Error: $e');
    }
  }

  /// Play sound effect
  Future<void> playScanSound() async {
    try {
      _scanSoundPool?.start();
    } catch (e) {
      debugPrint('❌ Error playing scan sound: $e');
    }
  }
}
