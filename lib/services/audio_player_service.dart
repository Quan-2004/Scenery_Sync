import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/music_models.dart';

// Repeat modes for playback
enum RepeatMode {
  off,   // No repeat
  one,   // Repeat current track
  all,   // Repeat entire queue
}

class AudioPlayerService {
  AudioPlayerService._internal();
  static final AudioPlayerService instance = AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Simple reactive state
  final StreamController<Track?> _trackController = StreamController.broadcast();
  final StreamController<bool> _playingController = StreamController.broadcast();
  final StreamController<double> _progressController = StreamController.broadcast();
  final StreamController<List<Track>> _queueController = StreamController.broadcast();
  final StreamController<bool> _shuffleController = StreamController.broadcast();
  final StreamController<RepeatMode> _repeatController = StreamController.broadcast();

  Track? _currentTrack;
  List<Track> _queue = [];
  List<Track> _originalQueue = []; // For shuffle functionality
  int _currentIndex = 0;
  bool _isShuffleOn = false;
  RepeatMode _repeatMode = RepeatMode.off;

  Stream<Track?> get trackStream => _trackController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<List<Track>> get queueStream => _queueController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<RepeatMode> get repeatStream => _repeatController.stream;

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _player.playing;
  List<Track> get queue => List.unmodifiable(_queue);
  bool get isShuffleOn => _isShuffleOn;
  RepeatMode get repeatMode => _repeatMode;
  int get currentIndex => _currentIndex;
  AudioPlayer get player => _player; // Expose player instance để lấy duration

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.positionStream.listen((pos) {
      final dur = _player.duration ?? Duration.zero;
      final pct = dur.inMilliseconds == 0
          ? 0.0
          : pos.inMilliseconds / dur.inMilliseconds;
      _progressController.add(pct.clamp(0.0, 1.0));
    });

    _player.playingStream.listen((playing) {
      _playingController.add(playing);
    });

    // Listen for track completion to auto-play next track
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  // Handle track completion based on repeat mode
  Future<void> _onTrackCompleted() async {
    if (_repeatMode == RepeatMode.one) {
      // Repeat current track
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (_queue.isNotEmpty && _currentIndex < _queue.length - 1) {
      // Play next track
      await skipToNext();
    } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      // Restart queue from beginning
      await skipToIndex(0);
    } else {
      // Queue finished, stop playback
      await _player.stop();
    }
  }

  // Queue management
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) {
      _queue = [];
      _originalQueue = [];
      _currentIndex = 0;
      _queueController.add(_queue);
      return;
    }

    _queue = List.from(tracks);
    _originalQueue = List.from(tracks);
    _currentIndex = startIndex.clamp(0, tracks.length - 1);
    _queueController.add(_queue);
    
    if (_currentIndex < _queue.length) {
      await setTrack(_queue[_currentIndex]);
    }
  }

  Future<void> addToQueue(Track track) async {
    _queue.add(track);
    _originalQueue.add(track);
    _queueController.add(_queue);
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    
    final removedTrack = _queue[index];
    _queue.removeAt(index);
    _originalQueue.remove(removedTrack);
    
    // Adjust current index if needed
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _queue.isNotEmpty) {
      // If we removed the current track, play the next one
      _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
      await setTrack(_queue[_currentIndex]);
    }
    
    _queueController.add(_queue);
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;
    
    final track = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, track);
    
    // Update current index
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    
    _queueController.add(_queue);
  }

  Future<void> clearQueue() async {
    _queue.clear();
    _originalQueue.clear();
    _currentIndex = 0;
    _queueController.add(_queue);
    await _player.stop();
  }

  // Playback controls
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await setTrack(_queue[_currentIndex]);
    await play();
  }

  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    
    // If we're more than 3 seconds into the song, restart it
    final position = _player.position;
    if (position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await setTrack(_queue[_currentIndex]);
    await play();
  }

  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    
    _currentIndex = index;
    await setTrack(_queue[_currentIndex]);
    await play();
  }

  // Shuffle functionality
  Future<void> toggleShuffle() async {
    _isShuffleOn = !_isShuffleOn;
    _shuffleController.add(_isShuffleOn);
    
    if (_isShuffleOn) {
      // Save current track to restore after shuffle
      final currentTrack = _currentTrack;
      
      // Shuffle the queue
      final random = Random();
      _queue.shuffle(random);
      
      // Move current track to the beginning if it exists
      if (currentTrack != null) {
        final currentTrackIndex = _queue.indexWhere((t) => t.id == currentTrack.id);
        if (currentTrackIndex != -1) {
          final track = _queue.removeAt(currentTrackIndex);
          _queue.insert(0, track);
          _currentIndex = 0;
        }
      }
    } else {
      // Restore original order
      final currentTrack = _currentTrack;
      _queue = List.from(_originalQueue);
      
      // Find current track in original queue
      if (currentTrack != null) {
        _currentIndex = _queue.indexWhere((t) => t.id == currentTrack.id);
        if (_currentIndex == -1) _currentIndex = 0;
      }
    }
    
    _queueController.add(_queue);
  }

  // Repeat functionality
  Future<void> toggleRepeat() async {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    _repeatController.add(_repeatMode);
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    _repeatController.add(_repeatMode);
  }

  Future<void> setTrack(Track track) async {
    debugPrint('🎵 Setting track: ${track.name} by ${track.artistName}');
    debugPrint('   Preview URL: ${track.previewUrl}');
    debugPrint('   Duration: ${track.durationMs}ms');
    
    _currentTrack = track;
    _trackController.add(track);

    try {
      if (track.localPath != null && track.localPath!.isNotEmpty) {
        // Play from local file
        debugPrint('   ▶️ Loading from local path: ${track.localPath}');
        await _player.setFilePath(track.localPath!);
      } else if (track.previewUrl != null && track.previewUrl!.isNotEmpty) {
        // Play from preview URL (Deezer or Firebase/Cloudinary)
        debugPrint('   ▶️ Loading from URL: ${track.previewUrl}');
        await _player.setUrl(track.previewUrl!);
      } else {
        throw Exception('No valid audio source available for this track');
      }
      debugPrint('   ✅ Track loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading track: $e');
      rethrow; // Throw error để UI có thể handle
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _trackController.close();
    await _playingController.close();
    await _progressController.close();
    await _queueController.close();
    await _shuffleController.close();
    await _repeatController.close();
  }
}
