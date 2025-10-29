import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/services/feed_service.dart';
import 'feed_state.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final feedServiceProvider = Provider((ref) {
  return FeedService(ref.watch(apiClientProvider));
});

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.watch(feedServiceProvider));
});

class FeedNotifier extends StateNotifier<FeedState> {
  final FeedService _feedService;
  static const int _pageSize = 10;

  FeedNotifier(this._feedService) : super(const FeedState()) {
    loadInitialFeed();
  }

  Future<void> loadInitialFeed() async {
    state = state.copyWith(status: FeedStatus.loading);
    
    try {
      final posts = await _feedService.fetchFeed(page: 1, pageSize: _pageSize);
      state = state.copyWith(
        status: FeedStatus.success,
        posts: posts,
        currentPage: 1,
        hasReachedMax: posts.length < _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        status: FeedStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMorePosts() async {
    if (state.hasReachedMax || state.status == FeedStatus.loadingMore) {
      return;
    }

    state = state.copyWith(status: FeedStatus.loadingMore);
    
    try {
      final nextPage = state.currentPage + 1;
      final newPosts = await _feedService.fetchFeed(
        page: nextPage,
        pageSize: _pageSize,
      );
      
      state = state.copyWith(
        status: FeedStatus.success,
        posts: [...state.posts, ...newPosts],
        currentPage: nextPage,
        hasReachedMax: newPosts.length < _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        status: FeedStatus.success,
        errorMessage: 'Failed to load more posts',
      );
    }
  }

  Future<void> refresh() async {
    state = const FeedState();
    await loadInitialFeed();
  }
}