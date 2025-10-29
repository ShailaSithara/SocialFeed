import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final String id;
  final String username;
  final String? profilePicture;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? description;
  final int likes;
  final int comments;
  final int shares;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.username,
    this.profilePicture,
    this.videoUrl,
    this.thumbnailUrl,
    this.description,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Parse video URL - API uses "video_link" field
    String? videoUrl = json['video_link'] ?? 
                       json['video_url'] ?? 
                       json['video'];
    
    // Parse thumbnail - API uses "thumbnail_url" or "gif_thumbnail_url"
    String? thumbnailUrl = json['thumbnail_url'] ?? 
                           json['gif_thumbnail_url'] ?? 
                           json['picture_url'];
    
    // Parse username - API uses "username" field
    String username = json['username'] ?? 
                     json['first_name'] ?? 
                     'Unknown';
    
    // Parse description - API might use "title" or "post_summary"
    String? description = json['title'] ?? 
                          json['post_summary'] ?? 
                          json['description'];

    return PostModel(
      id: json['id']?.toString() ?? json['identifier']?.toString() ?? '',
      username: username,
      profilePicture: json['picture_url'],
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      description: description,
      likes: _parseInt(json['upvote_count'] ?? json['likes']),
      comments: _parseInt(json['comment_count'] ?? json['comments']),
      shares: _parseInt(json['share_count'] ?? json['shares']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [
        id,
        username,
        profilePicture,
        videoUrl,
        thumbnailUrl,
        description,
        likes,
        comments,
        shares,
        createdAt,
      ];
}