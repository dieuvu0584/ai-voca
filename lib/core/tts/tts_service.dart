import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> init() async {
    await _tts.setSharedInstance(true);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Phát âm tự động (auto-TTS) — chỉ dùng flutter_tts, ổn định hơn
  Future<void> speak(String text, {String? audioUrl, String? ttsLang}) async {
    await _tts.stop();
    if (ttsLang != null) {
      await _tts.setLanguage(ttsLang);
    }
    await _tts.speak(text);
  }

  /// Phát âm bằng MP3 URL (khi user nhấn nút 🔊) — fallback TTS nếu fail
  Future<void> speakWithAudio(String text,
      {String? audioUrl, String? ttsLang}) async {
    await _tts.stop();
    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        return;
      } catch (_) {
        // Fallback to TTS
      }
    }
    if (ttsLang != null) {
      await _tts.setLanguage(ttsLang);
    }
    await _tts.speak(text);
  }

  /// Phát âm câu ví dụ
  Future<void> speakSentence(String sentence, {String? ttsLang}) async {
    if (ttsLang != null) {
      await _tts.setLanguage(ttsLang);
    }
    await _tts.setSpeechRate(0.4);
    await _tts.speak(sentence);
    await _tts.setSpeechRate(0.45);
  }

  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
  }

  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
  }
}
