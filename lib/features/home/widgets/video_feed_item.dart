import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/video/video_provider.dart';
import '../domain/models/post_model.dart';
import '../domain/services/like_service.dart';
import '../domain/services/comment_service.dart';
import 'video_player_widget.dart';

final likeServiceProvider = Provider((ref) => LikeService());
final commentServiceProvider = Provider((ref) => CommentService());

class VideoFeedItem extends ConsumerStatefulWidget {
  final PostModel post;
  final bool isActive;
  final int index;

  const VideoFeedItem({
    required this.post,
    required this.isActive,
    required this.index,
    super.key,
  });

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem>
    with TickerProviderStateMixin {
  bool _showDoubleTapHeart = false;
  late AnimationController _heartController;
  late AnimationController _buttonController;
  late Animation<double> _heartAnimation;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_heartController);

    _buttonScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showDoubleTapHeart = false);
      }
    });

    // Try to autoplay immediately if this is the active video
    if (widget.isActive) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && widget.isActive) {
          final videoManager = ref.read(videoManagerProvider);
          videoManager.play(widget.post.id);
          debugPrint('🎬 Auto-playing on init (active): ${widget.post.id}');
        }
      });
    }
  }

  @override
  void didUpdateWidget(VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _handleActiveStateChange();
    }
  }

  @override
  void dispose() {
    // Pause video when widget is disposed
    final videoManager = ref.read(videoManagerProvider);
    videoManager.pause(widget.post.id);
    _heartController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _handleActiveStateChange() {
    final videoManager = ref.read(videoManagerProvider);
    if (widget.isActive) {
      // Autoplay when active - with a small delay to ensure initialization
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && widget.isActive) {
          videoManager.play(widget.post.id);
          debugPrint('▶️ Attempting to play: ${widget.post.id}');
        }
      });
    } else {
      // Pause when not active
      videoManager.pause(widget.post.id);
      debugPrint('⏸️ Paused video: ${widget.post.id}');
    }
  }

  void _handleDoubleTap() async {
    final likeService = ref.read(likeServiceProvider);
    final isLiked = likeService.isLiked(widget.post.id);

    if (!isLiked) {
      setState(() => _showDoubleTapHeart = true);
      _heartController.forward(from: 0);
    }

    await likeService.toggleLike(widget.post.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final likeService = ref.watch(likeServiceProvider);
    final commentService = ref.watch(commentServiceProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      likeService.initializeLikeCount(widget.post.id, widget.post.likes);
      commentService.initializeCommentCount(widget.post.id, widget.post.comments);
    });

    final isLiked = likeService.isLiked(widget.post.id);
    final likeCount = likeService.getLikeCount(widget.post.id);
    final commentCount = commentService.getCommentCount(widget.post.id);

    return VisibilityDetector(
      key: Key('video-${widget.post.id}'),
      onVisibilityChanged: (info) {
        final videoManager = ref.read(videoManagerProvider);
        
        // Auto-play when more than 80% visible and active
        if (info.visibleFraction > 0.8 && widget.isActive) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && widget.isActive) {
              videoManager.play(widget.post.id);
              debugPrint('✅ Playing video: ${widget.post.id} (visibility: ${info.visibleFraction})');
            }
          });
        } 
        // Auto-pause when less than 50% visible
        else if (info.visibleFraction < 0.5) {
          videoManager.pause(widget.post.id);
          if (mounted) {
          }
          debugPrint('⏸️ Paused video: ${widget.post.id} (visibility: ${info.visibleFraction})');
        }
      },
      child: GestureDetector(
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video background
            VideoPlayerWidget(
              videoUrl: widget.post.videoUrl!,
              postId: widget.post.id,
              thumbnailUrl: widget.post.thumbnailUrl,
            ),

            // Heart animation
            if (_showDoubleTapHeart) _buildHeartAnimation(),

            // Overlay
            _buildOverlay(context, isLiked, likeCount, commentCount),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartAnimation() {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _heartAnimation,
          builder: (context, child) {
            final opacity = _heartAnimation.value > 0.8
                ? (1 - (_heartAnimation.value - 0.8) / 0.2)
                : 1.0;
            
            return Transform.scale(
              scale: _heartAnimation.value,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 120,
                    shadows: [
                      Shadow(
                        color: Color(0xFFFF3B5C),
                        blurRadius: 40,
                      ),
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverlay(
      BuildContext context, bool isLiked, int likeCount, int commentCount) {
    final likeService = ref.read(likeServiceProvider);

    return Stack(
      children: [
        // Enhanced gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // User info section
        Positioned(
          left: 16,
          bottom: 80,
          right: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username with verified badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '@${widget.post.username}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF3B82F6)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              if (widget.post.description?.isNotEmpty ?? false)
                Text(
                  widget.post.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Action buttons
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? const Color(0xFFFF3B5C) : Colors.white,
                count: likeCount,
                onTap: () async {
                  _buttonController.forward().then((_) => _buttonController.reverse());
                  await likeService.toggleLike(widget.post.id);
                  setState(() {});
                },
                isActive: isLiked,
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.mode_comment_rounded,
                color: Colors.white,
                count: commentCount,
                onTap: () async {
                  _buttonController.forward().then((_) => _buttonController.reverse());
                  final commentService = ref.read(commentServiceProvider);
                  final comments = await commentService.getComments(widget.post.id);
                  if (context.mounted) {
                    _showCommentSheet(context, comments);
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.share_rounded,
                color: Colors.white,
                count: widget.post.shares,
                onTap: () {
                  _buttonController.forward().then((_) => _buttonController.reverse());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return ScaleTransition(
      scale: _buttonScale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? RadialGradient(
                    colors: [
                      color.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 10,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatCount(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showCommentSheet(BuildContext context, List comments) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF0F0F1E),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${comments.length} Comments',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final c = comments[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.comment,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}