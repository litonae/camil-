import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barber_camil/core/theme/app_colors.dart';
import 'package:barber_camil/presentation/widgets/custom_button.dart';
import 'package:barber_camil/core/services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isAdminMode = false;
  final _adminCodeController = TextEditingController();
  final _supabaseService = SupabaseService();
  StreamSubscription<AuthState>? _authSubscription;

  final String _secretAdminCode = "070809";

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      if (session != null && mounted && event == AuthChangeEvent.signedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminAccess() async {
    if (_adminCodeController.text == _secretAdminCode) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else {
      _showMsg('ACCESO DENEGADO');
    }
  }

  void _showMsg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 1. FONDO CON REPAINT BOUNDARY PARA FLUIDEZ
          const RepaintBoundary(child: _EliteAnimatedBackground()),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: _isAdminMode ? _buildAdminEntryView() : _buildMainLoginView(),
            ),
          ),
          
          if (_isLoading) _buildGlobalLoading(),
        ],
      ),
    );
  }

  Widget _buildMainLoginView() {
    return Column(
      children: [
        const Spacer(flex: 3),
        
        // Logo con Animación Elástica Pro
        RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 20),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 3.seconds, curve: Curves.easeInOut),
              
              Image.asset('assets/images/logo.png', height: 140)
                .animate()
                .fadeIn(duration: 1.seconds)
                .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 2.seconds),
            ],
          ),
        ),
        
        const SizedBox(height: 60),
        
        const Text('CAMIL', 
          style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: 22, color: Colors.white)
        ).animate().shimmer(delay: 1.seconds, duration: 4.seconds).fadeIn(duration: 1.seconds),
        
        const Text('ATELIER DE HAUTE COIFFURE', 
          style: TextStyle(fontSize: 8, letterSpacing: 8, color: Colors.white24, fontWeight: FontWeight.w300)
        ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
        
        const Spacer(flex: 4),
        
        // Botón de Google de Cristal
        RepaintBoundary(
          child: _googleButton()
            .animate()
            .fadeIn(delay: 1.2.seconds)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack, duration: 1.seconds),
        ),
        
        const SizedBox(height: 30),
        
        GestureDetector(
          onTap: () => setState(() => _isAdminMode = true),
          child: const Opacity(
            opacity: 0.2,
            child: Text('ADMINISTRATION TERMINAL', 
              style: TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 7, fontWeight: FontWeight.bold)
            ),
          ),
        ).animate().fadeIn(delay: 2.seconds),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildAdminEntryView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 40, color: AppColors.primary).animate().shake().shimmer(),
        const SizedBox(height: 40),
        const Text('SECURE ACCESS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 8)),
        const SizedBox(height: 60),
        TextField(
          controller: _adminCodeController,
          maxLength: 6,
          textAlign: TextAlign.center,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 32, letterSpacing: 25, fontWeight: FontWeight.w200, color: Colors.white),
          decoration: const InputDecoration(
            counterText: "",
            hintText: "******",
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
          ),
          onChanged: (v) { if (v.length == 6) _handleAdminAccess(); },
        ),
        const SizedBox(height: 80),
        TextButton(
          onPressed: () => setState(() => _isAdminMode = false), 
          child: const Text('BACK', style: TextStyle(color: Colors.white10, letterSpacing: 4))
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _googleButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () => _supabaseService.signInWithGoogle(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white38)),
                SizedBox(width: 25),
                Text('CONTINUAR CON GOOGLE', 
                  style: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 4, fontSize: 10, color: Colors.white)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalLoading() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1),
            const SizedBox(height: 30),
            const Text('SYNCING SYSTEM', style: TextStyle(letterSpacing: 10, fontSize: 10, color: Colors.white24))
              .animate(onPlay: (c) => c.repeat()).shimmer(),
          ],
        ),
      ),
    );
  }
}

class _EliteAnimatedBackground extends StatelessWidget {
  const _EliteAnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.2,
              colors: [Color(0xFF1A0000), Color(0xFF050505)],
            ),
          ),
        ),
        // Scanner Lines optimizadas
        ...List.generate(2, (index) => Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.primary.withValues(alpha: 0.02), Colors.transparent],
                stops: const [0.49, 0.5, 0.51],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat())
           .moveY(begin: -800, end: 800, duration: (10 + (index * 5)).seconds),
        )),
      ],
    );
  }
}
