import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:energy_app/views/auth_screen.dart';
import 'package:energy_app/widgets/bottom_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<Color?> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _gradientAnimation = ColorTween(
      begin: const Color(0xFF42A5F5),
      end: const Color(0xFF0D47A1),
    ).animate(_controller);

    Future.delayed(const Duration(seconds: 4), () {
      final user = FirebaseAuth.instance.currentUser;

      if (mounted) {
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BottomNav()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      const Color(0xFFE3F2FD),
                      _gradientAnimation.value!,
                    ],
                    stops: const [0.1, 1.0],
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: -100,
            top: -50,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.bolt,
                size: 300,
                color: Colors.blue[900],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF64B5F6).withOpacity(0.2),
                                _gradientAnimation.value!.withOpacity(0.4),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _gradientAnimation.value!.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Image.asset(
                              'assets/brain71.png',
                              width: 180,
                              height: 180,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'EnergyTrack',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white, // Couleur blanche appliquée ici
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Text(
                        'Énergie en parfaite harmonie',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey[100],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _gradientAnimation.value!,
                      ),
                      strokeWidth: 4,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
