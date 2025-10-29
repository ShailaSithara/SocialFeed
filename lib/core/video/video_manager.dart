import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoManager {
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, bool> _initializationStatus = {};
  String? _currentPlayingId;

  Future<VideoPlayerController?> getController(String videoUrl, String id) async {
    if (_controllers.containsKey(id)) {
      return _controllers[id]!;
    }

    // Prevent duplicate initialization
    if (_initializationStatus[id] == true) {
      return null;
    }

    _initializationStatus[id] = true;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
      
      _controllers[id] = controller;
      
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(1.0);
      
      debugPrint('✅ Video initialized successfully: $id');
      return controller;
    } catch (e) {
      debugPrint('❌ Error initializing video $id: $e');
      _controllers.remove(id);
      _initializationStatus.remove(id);
      return null;
    }
  }

  Future<void> preloadVideo(String videoUrl, String id) async {
    if (!_controllers.containsKey(id) && _initializationStatus[id] != true) {
      await getController(videoUrl, id);
    }
  }

  Future<void> play(String id) async {
    debugPrint('▶️ Attempting to play: $id');
    
    // Pause currently playing video
    if (_currentPlayingId != null && _currentPlayingId != id) {
      if (_controllers.containsKey(_currentPlayingId!)) {
        await _controllers[_currentPlayingId!]?.pause();
        debugPrint('⏸️ Paused previous video: $_currentPlayingId');
      }
    }

    // Play new video
    if (_controllers.containsKey(id)) {
      final controller = _controllers[id]!;
      if (controller.value.isInitialized) {
        await controller.play();
        _currentPlayingId = id;
        debugPrint('✅ Playing video: $id');
      } else {
        debugPrint('⚠️ Video not initialized: $id');
      }
    } else {
      debugPrint('⚠️ Controller not found: $id');
    }
  }

  Future<void> pause(String id) async {
    if (_controllers.containsKey(id)) {
      await _controllers[id]?.pause();
      debugPrint('⏸️ Paused video: $id');
    }
    if (_currentPlayingId == id) {
      _currentPlayingId = null;
    }
  }

  void disposeController(String id) {
    if (_controllers.containsKey(id)) {
      _controllers[id]?.dispose();
      _controllers.remove(id);
      _initializationStatus.remove(id);
      debugPrint('🗑️ Disposed controller: $id');
    }
    if (_currentPlayingId == id) {
      _currentPlayingId = null;
    }
  }

  void disposeAll() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _initializationStatus.clear();
    _currentPlayingId = null;
    debugPrint('🗑️ Disposed all controllers');
  }

  bool isInitialized(String id) {
    return _controllers[id]?.value.isInitialized ?? false;
  }

  VideoPlayerController? getExistingController(String id) {
    return _controllers[id];
  }

  String? get currentPlayingId => _currentPlayingId;
}