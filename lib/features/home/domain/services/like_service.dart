class LikeService {
  final Map<String, bool> _likedPosts = {};
  final Map<String, int> _likeCounts = {};

  /// Whether user already liked this post
  bool isLiked(String postId) => _likedPosts[postId] ?? false;

  /// Returns the total like count (base + local changes)
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

  /// Initialize the base like count from PostModel
  void initializeLikeCount(String postId, int baseCount) {
    // Only set once (avoid resetting after user toggles)
    _likeCounts.putIfAbsent(postId, () => baseCount);
  }

  /// Toggle like and update the local count
  Future<bool> toggleLike(String postId) async {
    await Future.delayed(const Duration(milliseconds: 250)); // Simulate network

    final currentState = _likedPosts[postId] ?? false;
    _likedPosts[postId] = !currentState;

    // Ensure post has initialized count
    _likeCounts.putIfAbsent(postId, () => 0);

    // Increase or decrease like count
    if (!currentState) {
      _likeCounts[postId] = _likeCounts[postId]! + 1;
    } else {
      _likeCounts[postId] = (_likeCounts[postId]! - 1).clamp(0, double.infinity).toInt();
    }

    print('${!currentState ? "Liked" : "Unliked"} post: $postId');
    return !currentState;
  }
}
