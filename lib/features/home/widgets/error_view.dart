import 'package:flutter/material.dart';
import 'dart:math' as math;

class ErrorView extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool showRetry;

  const ErrorView({
    required this.message,
    this.onRetry,
    this.showRetry = true,
    super.key,
  });

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.showRetry;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isError
              ? [
                  const Color(0xFF2D1B3D),
                  const Color(0xFF1A1535),
                  Colors.black,
                ]
              : [
                  const Color(0xFF1A1535),
                  Colors.black,
                ],
        ),
      ),
      child: Stack(
        children: [
          // Animated background particles
          ...List.generate(12, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = (_controller.value + index * 0.08) % 1.0;
                final x = 30.0 + index * 30.0;
                final y = MediaQuery.of(context).size.height * 0.2 +
                    math.sin(progress * math.pi * 2) * 100;
                
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: (math.sin(progress * math.pi) * 0.2).clamp(0.0, 1.0),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isError
                            ? const Color(0xFFFF3B5C)
                            : const Color(0xFF4A90E2),
                        boxShadow: [
                          BoxShadow(
                            color: isError
                                ? const Color(0xFFFF3B5C).withOpacity(0.5)
                                : const Color(0xFF4A90E2).withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with glow effect
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    isError
                                        ? const Color(0xFFFF3B5C).withOpacity(0.2)
                                        : const Color(0xFF4A90E2).withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                ),
                                border: Border.all(
                                  color: isError
                                      ? const Color(0xFFFF3B5C).withOpacity(0.3)
                                      : const Color(0xFF4A90E2).withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isError
                                        ? const Color(0xFFFF3B5C).withOpacity(0.4)
                                        : const Color(0xFF4A90E2).withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.showRetry
                                    ? Icons.error_outline_rounded
                                    : Icons.inbox_rounded,
                                size: 72,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: isError
                                        ? const Color(0xFFFF3B5C)
                                        : const Color(0xFF4A90E2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Error message
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isError ? 'Oops!' : 'Nothing Here',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 15,
                                    height: 1.6,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          if (widget.showRetry && widget.onRetry != null) ...[
                            const SizedBox(height: 40),
                            
                            // Retry button
                            _RetryButton(
                              onPressed: widget.onRetry!,
                              controller: _controller,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  final VoidCallback onPressed;
  final AnimationController controller;

  const _RetryButton({
    required this.onPressed,
    required this.controller,
  });

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _buttonController.forward(),
        onTapUp: (_) {
          _buttonController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _buttonController.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF3B5C),
                Color(0xFFFF66B2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B5C).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}