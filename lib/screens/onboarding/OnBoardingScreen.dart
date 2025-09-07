import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../auth/LoginScreen.dart';

class AnimatedParticle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  Color color;
  double opacity;

  AnimatedParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.color,
    required this.opacity,
  });
}

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _gradientAnimation;
  late Animation<double> _pulseAnimation;

  List<AnimatedParticle> particles = [];
  final int particleCount = 50;

  @override
  void initState() {
    super.initState();

    // Gradient animation controller
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _initializeParticles();

    _particleController.addListener(() {
      _updateParticles();
    });
  }

  void _initializeParticles() {
    particles.clear();
    final random = math.Random();

    for (int i = 0; i < particleCount; i++) {
      particles.add(
        AnimatedParticle(
          x: random.nextDouble() * 400,
          y: random.nextDouble() * 800,
          size: random.nextDouble() * 3 + 1,
          speedX: (random.nextDouble() - 0.5) * 0.5,
          speedY: (random.nextDouble() - 0.5) * 0.3,
          color: Color.fromRGBO(
            150 + random.nextInt(105),
            100 + random.nextInt(155),
            255,
            1,
          ),
          opacity: random.nextDouble() * 0.6 + 0.1,
        ),
      );
    }
  }

  void _updateParticles() {
    for (var particle in particles) {
      particle.x += particle.speedX;
      particle.y += particle.speedY;

      // Wrap around screen
      if (particle.x < 0) particle.x = 400;
      if (particle.x > 400) particle.x = 0;
      if (particle.y < 0) particle.y = 800;
      if (particle.y > 800) particle.y = 0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5 + (_gradientAnimation.value * 0.5),
                    colors: [
                      Color.lerp(
                        const Color(0xFF2D1B69),
                        const Color(0xFF4A148C),
                        _gradientAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF1A0E2E),
                        const Color(0xFF311B92),
                        _gradientAnimation.value * 0.7,
                      )!,
                      const Color(0xFF000000),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),

          // Floating Particles
          CustomPaint(
            painter: ParticlePainter(particles),
            size: screenSize,
          ),

          // Animated Overlay Gradients
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.withOpacity(0.1 * _gradientAnimation.value),
                      Colors.transparent,
                      Colors.deepPurple.withOpacity(0.2 * (1 - _gradientAnimation.value)),
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated Decorative Elements
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Positioned(
                top: -50,
                right: -50,
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purple.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: 100,
                left: -30,
                child: Transform.scale(
                  scale: 2 - _pulseAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Moving Gradient Overlay
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1 + (0.1 * _gradientAnimation.value)),
                      Colors.black.withOpacity(0.4 + (0.2 * _gradientAnimation.value)),
                      Colors.black.withOpacity(0.7 + (0.1 * _gradientAnimation.value)),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // Header with fade-in animation
                  AnimatedBuilder(
                    animation: _gradientAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.6 + (0.4 * _gradientAnimation.value),
                        child: Text(
                          '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Brand Name with pulse animation
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.95 + (0.05 * _pulseAnimation.value),
                          child: Column(
                            children: [
                              Text(
                                'Molafzo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 70,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Cursive',
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 4),
                                      blurRadius: 10 + (5 * _pulseAnimation.value),
                                      color: Colors.purple.withOpacity(0.3),
                                    ),
                                    Shadow(
                                      offset: const Offset(0, 8),
                                      blurRadius: 20,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Shop Smarter, Live Better.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Buttons Container with hover effects
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Login Button
                        AnimatedBuilder(
                          animation: _gradientAnimation,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Color.lerp(Colors.white, Colors.purple.shade50, _gradientAnimation.value * 0.3)!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 4),
                                    blurRadius: 15 + (10 * _gradientAnimation.value),
                                    color: Colors.purple.withOpacity(0.1 + (0.1 * _gradientAnimation.value)),
                                  ),
                                  BoxShadow(
                                    offset: const Offset(0, 8),
                                    blurRadius: 25,
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle login
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>AuthScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Sign Up Button
                        AnimatedBuilder(
                          animation: _gradientAnimation,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Color.lerp(
                                    Colors.white.withOpacity(0.3),
                                    Colors.purple.withOpacity(0.5),
                                    _gradientAnimation.value,
                                  )!,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.purple.withOpacity(0.05 * _gradientAnimation.value),
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle sign up
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<AnimatedParticle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Main App
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Molafzo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.grey,
        fontFamily: 'Inter',
      ),
      home: const OnBoardingScreen(),
    );
  }
}

void main() {
  runApp(const MyApp());
}