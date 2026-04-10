import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentPlayingPath => _currentPlayingPath;

  Future<String> _getAudioPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final uuid = const Uuid().v4();
    return '${dir.path}/voice_$uuid.m4a';
  }

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String?> startRecording() async {
    if (_isRecording) return null;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;

    final path = await _getAudioPath();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _isRecording = true;
    return path;
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    await _recorder.stop();
    _isRecording = false;
  }

  Future<void> playAudio(String path) async {
    if (_isPlaying && _currentPlayingPath == path) {
      await stopPlayback();
      return;
    }

    if (_isPlaying) {
      await _player.stop();
    }

    await _player.play(DeviceFileSource(path));
    _isPlaying = true;
    _currentPlayingPath = path;

    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentPlayingPath = null;
    });
  }

  Future<void> stopPlayback() async {
    await _player.stop();
    _isPlaying = false;
    _currentPlayingPath = null;
  }

  Future<Duration?> getAudioDuration(String path) async {
    await _player.setSource(DeviceFileSource(path));
    return await _player.getDuration();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
