import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../firebase_options.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation instantanée style Netflix — 600ms
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.3, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Lancer l'animation immédiatement
    _controller.forward();

    // Initialiser Firebase en arrière-plan pendant que le splash s'affiche
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Firebase s'initialise pendant que l'animation joue
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Erreur init Firebase: $e');
    }

    // Attendre que l'animation soit terminée (minimum 1.5s pour voir le splash)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Redirection selon l'état de connexion
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.go('/partner/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cercle décoratif haut droite
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC9970C).withOpacity(0.04),
              ),
            ),
          ),

          // Cercle décoratif bas gauche
          Positioned(
            bottom: -120,
            left: -120,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1B3A6B).withOpacity(0.25),
              ),
            ),
          ),

          // Logo centré — style Netflix : zoom arrière + fade
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cercle trident
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFC9970C)
                                .withOpacity(0.08),
                            border: Border.all(
                              color: const Color(0xFFC9970C)
                                  .withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '🔱',
                              style: TextStyle(fontSize: 52),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // RL EXPRESS
                        const Text(
                          'RL EXPRESS',
                          style: TextStyle(
                            color: Color(0xFFC9970C),
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Slogan
                        const Text(
                          'La rapidité au service de vos besoins',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Devise
                        const Text(
                          'Disponibilité · Rapidité · Fiabilité',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Barre de progression style Netflix en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0A1628),
                          Color(0xFFC9970C),
                          Color(0xFF0A1628),
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