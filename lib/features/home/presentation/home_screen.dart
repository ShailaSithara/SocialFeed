import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/feed_state.dart';
import '../widgets/video_feed_item.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../../../core/video/video_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool feedPreloaded;
  
  const HomeScreen({this.feedPreloaded = false, super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    if (!widget.feedPreloaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(feedProvider.notifier).loadInitialFeed();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoplayFirstVideo();
      });
    }
  }

  void _autoplayFirstVideo() {
    final feedState = ref.read(feedProvider);
    if (feedState.posts.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final videoManager = ref.read(videoManagerProvider);
          videoManager.play(feedState.posts[0].id);
          debugPrint('🎬 Auto-playing first video');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    ref.listen(feedProvider, (previous, next) {
      if (previous?.status != FeedStatus.success && 
          next.status == FeedStatus.success && 
          next.posts.isNotEmpty &&
          !widget.feedPreloaded) {
        _autoplayFirstVideo();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main Content
          Builder(
            builder: (context) {
              if (feedState.status == FeedStatus.loading && feedState.posts.isEmpty) {
                return const LoadingView();
              }

              if (feedState.status == FeedStatus.failure && feedState.posts.isEmpty) {
                return ErrorView(
                  message: feedState.errorMessage ?? 'An error occurred',
                  onRetry: () => ref.read(feedProvider.notifier).loadInitialFeed(),
                );
              }

              if (feedState.posts.isEmpty) {
                return const ErrorView(
                  message: 'No posts available',
                  showRetry: false,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(feedProvider.notifier).refresh();
                  setState(() => _currentPage = 0);
                  _autoplayFirstVideo();
                },
                backgroundColor: const Color(0xFF1A1A2E),
                color: const Color(0xFFFF3B5C),
                strokeWidth: 3,
                displacement: 60,
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  itemCount: feedState.posts.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentPage = index);
                    
                    if (index >= feedState.posts.length - 2) {
                      ref.read(feedProvider.notifier).loadMorePosts();
                    }
                  },
                  itemBuilder: (context, index) {
                    return VideoFeedItem(
                      post: feedState.posts[index],
                      index: index,
                      isActive: index == _currentPage,
                    );
                  },
                ),
              );
            },
          ),
          
          // Beautiful Top Bar
          SafeArea(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF3B5C),
                            Color(0xFFFF66B2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B5C).withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFF3B5C),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Social Feed',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Search Button
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.search, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Search coming soon!'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF1A1A2E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notification Button
                    Stack(
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.notifications, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('No new notifications'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF1A1A2E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B5C),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF3B5C).withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading More Indicator
          if (feedState.status == FeedStatus.loadingMore)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A1A2E).withOpacity(0.9),
                        const Color(0xFF16213E).withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFFFF3B5C).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF3B5C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading more...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }
}