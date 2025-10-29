import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/post_model.dart';
import '../providers/feed_provider.dart';
import 'video_feed_item.dart';

class FeedListView extends ConsumerStatefulWidget {
  final List<PostModel> posts;

  const FeedListView({required this.posts, super.key});

  @override
  ConsumerState<FeedListView> createState() => _FeedListViewState();
}

class _FeedListViewState extends ConsumerState<FeedListView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _pageController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      ref.read(feedProvider.notifier).loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: Colors.pinkAccent,
      backgroundColor: Colors.black,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.posts.length,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemBuilder: (context, index) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: index == _currentPage ? 1.0 : 0.4,
            child: VideoFeedItem(
              post: widget.posts[index],
              isActive: index == _currentPage,
              index: index,
            ),
          );
        },
      ),
    );
  }
}
