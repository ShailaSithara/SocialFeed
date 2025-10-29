import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;
  late Animation<double> _rotate;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleUp = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideUp = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _rotate = Tween<double>(begin: 0, end: 2 * pi).animate(_rotateController);

    _shimmer = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 900),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Widget _buildFloatingParticle({
    required double size,
    required Color color,
    required double initialX,
    required double initialY,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + delay) % 1.0;
        final x = initialX + sin(progress * 2 * pi) * 40;
        final y = initialY - progress * 500;
        final opacity = (1 - progress) * 0.7;
        final scale = 1.0 - (progress * 0.5);

        return Positioned(
          left: x,
          top: y,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.9),
                      color.withOpacity(0.3),
                      color.withOpacity(0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final random = Random(42);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A0E27),
                      Color.lerp(
                        const Color(0xFF1A1535),
                        const Color(0xFF2D1B3D),
                        (sin(_particleController.value * pi) * 0.3 + 0.3)
                            .clamp(0.0, 1.0),
                      )!,
                      const Color(0xFF0F0F23),
                    ],
                  ),
                ),
              );
            },
          ),

          // Rotating gradient orbs
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: height * 0.2 + sin(_rotate.value) * 50,
                    left: width * 0.1 + cos(_rotate.value) * 50,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFF3B5C).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: height * 0.15 + cos(_rotate.value * 1.5) * 60,
                    right: width * 0.1 + sin(_rotate.value * 1.5) * 60,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00E5FF).withOpacity(0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Floating Particles
          ...List.generate(20, (index) {
            return _buildFloatingParticle(
              size: random.nextDouble() * 10 + 3,
              color: index % 4 == 0
                  ? const Color(0xFFFF3B5C)
                  : index % 4 == 1
                      ? const Color(0xFF00E5FF)
                      : index % 4 == 2
                          ? const Color(0xFFFF66B2)
                          : const Color(0xFF9D4EDD),
              initialX: random.nextDouble() * width,
              initialY: height + random.nextDouble() * 150,
              delay: random.nextDouble(),
            );
          }),

          // Center Content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: ScaleTransition(
                      scale: _scaleUp,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Premium Logo
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Rotating outer ring
                              AnimatedBuilder(
                                animation: _rotateController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _rotate.value,
                                    child: Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: SweepGradient(
                                          colors: [
                                            const Color(0xFFFF3B5C).withOpacity(0.0),
                                            const Color(0xFFFF3B5C).withOpacity(0.5),
                                            const Color(0xFF00E5FF).withOpacity(0.5),
                                            const Color(0xFFFF3B5C).withOpacity(0.0),
                                          ],
                                          stops: const [0.0, 0.3, 0.7, 1.0],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Pulsing glow
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 170 * _pulse.value,
                                    height: 170 * _pulse.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFFFF3B5C)
                                              .withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Main logo
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF0844),
                                      Color(0xFFFF3B5C),
                                      Color(0xFFFF66B2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF3B5C)
                                          .withOpacity(0.7),
                                      blurRadius: 60,
                                      spreadRadius: 15,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFFF66B2)
                                          .withOpacity(0.5),
                                      blurRadius: 90,
                                      spreadRadius: 25,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.4),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: Colors.white,
                                      size: 85,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 50),

                          // Animated Shimmer Text
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: const [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFFF3B5C),
                                    Color(0xFFFF66B2),
                                    Color(0xFF00E5FF),
                                    Color(0xFFFFFFFF),
                                  ],
                                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                                  begin: Alignment(_shimmer.value, 0),
                                  end: Alignment(_shimmer.value + 1, 0),
                                ).createShader(bounds),
                                child: const Text(
                                  'Social Feed',
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 3.5,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFFFF3B5C),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 18),
                          
                          // Premium Tagline
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.03),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF3B5C).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTaglineText('Watch'),
                                _buildDot(),
                                _buildTaglineText('Connect'),
                                _buildDot(),
                                _buildTaglineText('Inspire'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 60),

                          // Premium Loading Indicator
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulsing ring
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 70 * _pulse.value,
                                    height: 70 * _pulse.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFF3B5C)
                                            .withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Spinning gradient ring
                              SizedBox(
                                width: 55,
                                height: 55,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  strokeCap: StrokeCap.round,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF3B5C),
                                  ),
                                ),
                              ),
                              // Center dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF3B5C),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF3B5C),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Animated Line
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Center(
                  child: Container(
                    width: width * 0.5,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color.lerp(
                            const Color(0xFFFF3B5C),
                            const Color(0xFF00E5FF),
                            (sin(_shimmerController.value * pi) + 1) / 2,
                          )!.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B5C).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
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

  Widget _buildTaglineText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: Colors.white.withOpacity(0.95),
        letterSpacing: 2.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFFFF3B5C),
              Color(0xFFFF66B2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B5C).withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}