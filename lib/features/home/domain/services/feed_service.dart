import '../../../../core/network/api_client.dart';
import '../models/post_model.dart';

class FeedService {
  final ApiClient _apiClient;

  FeedService(this._apiClient);

  Future<List<PostModel>> fetchFeed({
    required int page,
    required int pageSize,
  }) async {
    print('📡 Fetching feed: page=$page, pageSize=$pageSize');
    
    final response = await _apiClient.get(
      '/feed',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );

    print('📦 API Response received');
    print('📦 Response type: ${response.runtimeType}');
    print('📦 Response keys: ${response.keys.toList()}');
    
    List<dynamic> posts = [];

    // Detect where the posts array is located
    if (response.containsKey('posts') && response['posts'] is List) {
      posts = response['posts'];
      print('✅ Found ${posts.length} posts in response["posts"]');
    } else if (response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        posts = data;
      } else if (data is Map && data.containsKey('posts') && data['posts'] is List) {
        posts = data['posts'];
      }
    } else if (response.containsKey('results') && response['results'] is List) {
      posts = response['results'];
    } else if (response.containsKey('items') && response['items'] is List) {
      posts = response['items'];
    } else {
      print('⚠️ No posts array found. Keys: ${response.keys}');
    }

    if (posts.isEmpty) {
      print('⚠️ No posts found in API response');
      return [];
    }

    print('📊 Processing ${posts.length} posts');
    final parsedPosts = <PostModel>[];

    for (int i = 0; i < posts.length; i++) {
      try {
        final rawPost = posts[i];
        if (rawPost is Map<String, dynamic>) {
          final post = PostModel.fromJson(rawPost);
          if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
            parsedPosts.add(post);
            print('✅ Post ${i + 1}: ${post.id} - video found');
          } else {
            print('⚠️ Post ${i + 1}: ${post.id} has no video URL');
          }
        } else {
          print('⚠️ Skipping post ${i + 1}: Invalid type ${rawPost.runtimeType}');
        }
      } catch (e, stack) {
        print('❌ Error parsing post ${i + 1}: $e');
        print(stack);
      }
    }

    print('✅ Successfully parsed ${parsedPosts.length} valid posts');
    return parsedPosts;
  }
}
