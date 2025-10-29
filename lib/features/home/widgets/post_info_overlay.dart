import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/post_model.dart';
import '../domain/services/like_service.dart';
import '../domain/services/comment_service.dart';

final likeServiceProvider = Provider((ref) => LikeService());
final commentServiceProvider = Provider((ref) => CommentService());

class PostInfoOverlay extends ConsumerStatefulWidget {
  final PostModel post;

  const PostInfoOverlay({super.key, required this.post});

  @override
  ConsumerState<PostInfoOverlay> createState() => _PostInfoOverlayState();
}

class _PostInfoOverlayState extends ConsumerState<PostInfoOverlay> {
  int _likeCount = 0;
  int _commentCount = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final likeService = ref.read(likeServiceProvider);
    final commentService = ref.read(commentServiceProvider);

    final likeCount = likeService.getLikeCount(widget.post.id);
    final commentCount = commentService.getCommentCount(widget.post.id);
    final isLiked = likeService.isLiked(widget.post.id);

    setState(() {
      _likeCount = likeCount;
      _commentCount = commentCount;
      _isLiked = isLiked;
    });
  }

  Future<void> _toggleLike() async {
    final likeService = ref.read(likeServiceProvider);
    final newLikedState = await likeService.toggleLike(widget.post.id);
    final newCount = likeService.getLikeCount(widget.post.id);

    setState(() {
      _isLiked = newLikedState;
      _likeCount = newCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ Gradient overlay for readability
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black87,
                  Colors.transparent,
                ],
                stops: [0.0, 0.6],
              ),
            ),
          ),
        ),

        // ✅ Info content
        Positioned(
          bottom: 20,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${widget.post.username}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.post.description != null && widget.post.description!.isNotEmpty)
                Text(
                  widget.post.description!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        // ✅ Action buttons (right side)
        Positioned(
          bottom: 60,
          right: 12,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // ❤️ Like button
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.redAccent : Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_likeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 💬 Comment button
              Column(
                children: [
                  const Icon(Icons.comment, color: Colors.white, size: 30),
                  const SizedBox(height: 4),
                  Text(
                    '$_commentCount',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 🔁 Share button
              Column(
                children: const [
                  Icon(Icons.share, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Share',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
