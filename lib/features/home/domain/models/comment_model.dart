class CommentModel {
  final String id;
  final String username;
  final String? profilePicture;
  final String comment;
  final DateTime createdAt;
  final int likes;

  CommentModel({
    required this.id,
    required this.username,
    this.profilePicture,
    required this.comment,
    required this.createdAt,
    this.likes = 0,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}