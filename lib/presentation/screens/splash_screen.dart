import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      // Por ahora vamos a la Home, luego implementaremos auth logic
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fondo con gradiente sutil
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF1A0000),
                  AppColors.background,
                ],
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                )
                .animate()
                .fadeIn(duration: 1200.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 1500.ms, color: Colors.white24),

                const SizedBox(height: 24),

                const Text(
                  'CAMIL',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: AppColors.textPrimary,
                  ),
                )
                .animate()
                .fadeIn(delay: 600.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0),

                const Text(
                  'BARBER EXPERIENCE',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 4,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w300,
                  ),
                )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 800.ms),
              ],
            ),
          ),

          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
              .animate()
              .fadeIn(delay: 2000.ms),
            ),
          ),
        ],
      ),
    );
  }
}
