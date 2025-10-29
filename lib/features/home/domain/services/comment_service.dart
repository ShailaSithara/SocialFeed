import '../models/comment_model.dart';

class CommentService {
  final Map<String, List<CommentModel>> _comments = {};
  final Map<String, int> _commentCounts = {};
  int _commentIdCounter = 0;

  void initializeCommentCount(String postId, int baseCount) {
    _commentCounts.putIfAbsent(postId, () => baseCount);
  }

  Future<List<CommentModel>> getComments(String postId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _comments[postId] ?? [];
  }

  Future<CommentModel> addComment(String postId, String text, String username) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final newComment = CommentModel(
      id: 'comment_${_commentIdCounter++}',
      username: username,
      comment: text,
      createdAt: DateTime.now(),
      likes: 0,
    );

    _comments.putIfAbsent(postId, () => []);
    _comments[postId]!.insert(0, newComment);
    _commentCounts[postId] = (_commentCounts[postId] ?? 0) + 1;

    return newComment;
  }

  int getCommentCount(String postId) => _commentCounts[postId] ?? 0;
}
