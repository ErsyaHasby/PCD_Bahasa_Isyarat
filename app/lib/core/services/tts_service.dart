import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _tts.awaitSpeakCompletion(true);
      
      // Ambil daftar bahasa yang tersedia di sistem
      final languages = await _tts.getLanguages;
      print('DEBUG TTS: Available Languages: $languages');

      // Periksa apakah bahasa Indonesia didukung
      final isAvailable = await _tts.isLanguageAvailable('id-ID');
      print('DEBUG TTS: isLanguageAvailable("id-ID") = $isAvailable');

      if (isAvailable) {
        await _tts.setLanguage('id-ID');
      } else {
        final isIdAvailable = await _tts.isLanguageAvailable('id');
        print('DEBUG TTS: isLanguageAvailable("id") = $isIdAvailable');
        if (isIdAvailable) {
          await _tts.setLanguage('id');
        }
      }

      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      
      _isInitialized = true;
      print('DEBUG TTS: Initialization complete.');
    } catch (e) {
      print('TTS Init Error: $e');
    }
  }

  Future<void> speak(String text) async {
    await initialize();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async => await _tts.stop();

  void dispose() {
    _tts.stop();
  }
}
