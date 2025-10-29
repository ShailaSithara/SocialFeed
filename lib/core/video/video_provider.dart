import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'video_manager.dart';

final videoManagerProvider = Provider((ref) {
  final manager = VideoManager();
  
  ref.onDispose(() {
    manager.disposeAll();
  });
  
  return manager;
});