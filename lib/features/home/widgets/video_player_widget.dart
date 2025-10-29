import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/video/video_provider.dart';

class VideoPlayerWidget extends ConsumerStatefulWidget {
  final String videoUrl;
  final String postId;
  final String? thumbnailUrl;

  const VideoPlayerWidget({
    required this.videoUrl,
    required this.postId,
    this.thumbnailUrl,
    super.key,
  });

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final videoManager = ref.read(videoManagerProvider);
    
    try {
      final controller = await videoManager.getController(
        widget.videoUrl,
        widget.postId,
      );
      
      if (controller != null && mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = controller.value.isInitialized;
          _hasError = false;
        });
        
        // Listen to controller changes
        controller.addListener(_videoListener);
        
        // Auto-play after initialization (add small delay)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _controller != null && _controller!.value.isInitialized) {
            videoManager.play(widget.postId);
            debugPrint('🎬 Auto-playing after init: ${widget.postId}');
          }
        });
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize video';
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        // Check if it's an emulator codec error
        final isCodecError = e.toString().contains('Decoder init failed') ||
                            e.toString().contains('MediaCodec');
        setState(() {
          _hasError = true;
          _errorMessage = isCodecError 
              ? '⚠️ Emulator codec issue\nPlease test on real device'
              : 'Failed to load video';
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      if (_controller!.value.hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video playback error';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    
    final videoManager = ref.read(videoManagerProvider);
    if (_controller!.value.isPlaying) {
      videoManager.pause(widget.postId);
    } else {
      videoManager.play(widget.postId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Show error state with thumbnail
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Show thumbnail if available
            if (widget.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            // Error overlay
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage ?? 'Failed to load video',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🔗 Video link available',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Loading state
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox(),
              ),
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }

    // Video player - NO play/pause overlay
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}