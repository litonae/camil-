import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/supabase_service.dart';

class BlackCardScreen extends StatefulWidget {
  const BlackCardScreen({super.key});

  @override
  State<BlackCardScreen> createState() => _BlackCardScreenState();
}

class _BlackCardScreenState extends State<BlackCardScreen> with TickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late AnimationController _flipController;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) _flipController.forward(); else _flipController.reverse();
    _isFront = !_isFront;
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _supabaseService.getProfileStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          
          final profile = snapshot.data!;
          final int visits = profile['total_visits'] ?? 0;
          final String name = profile['full_name'] ?? 'Danae Morales';
          final String userId = profile['id'];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(),
                      const SizedBox(height: 30),
                      
                      // TARJETA 3D CON TONO ROJO PREMIUM
                      GestureDetector(
                        onTap: _toggleCard,
                        child: AnimatedBuilder(
                          animation: _flipController,
                          builder: (context, child) {
                            final angle = _flipController.value * math.pi;
                            return Transform(
                              transform: Matrix4.identity()..setEntry(3, 2, 0.0012)..rotateY(angle),
                              alignment: Alignment.center,
                              child: angle < math.pi / 2
                                  ? _CardFront(name: name, visits: visits)
                                  : Transform(transform: Matrix4.identity()..rotateY(math.pi), alignment: Alignment.center, child: _CardBack(name: name, userId: userId)),
                            );
                          },
                        ),
                      ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),

                      const SizedBox(height: 40),
                      _buildStatusPanel(visits),
                      const SizedBox(height: 40),
                      _buildDynamicsSection(), // NUEVA SECCIÓN DE DINÁMICA
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 70, pinned: true, backgroundColor: const Color(0xFF050505), elevation: 0,
      centerTitle: true, title: Text('MEMBRESÍA ATELIER', style: GoogleFonts.sora(letterSpacing: 6, fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white30)),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      Text("THE BLACK CARD EXPERIENCE", 
        style: GoogleFonts.sora(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 4)),
      const SizedBox(height: 8),
      Container(height: 1, width: 40, color: AppColors.primary.withValues(alpha: 0.3)),
    ]);
  }

  Widget _buildStatusPanel(int visits) {
    int current = visits % 6;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ESTADO DE VISITAS", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text("${6 - current} PARA TU REGALO", style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
          CircularProgressIndicator(value: current / 6, strokeWidth: 3, backgroundColor: Colors.white10, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildDynamicsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 12),
              Text("¿CÓMO FUNCIONA?", style: GoogleFonts.sora(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          _dynamicStep("1", "MUESTRA TU QR", "En cada visita al Atelier, gira tu tarjeta y pide que escaneen tu código personal."),
          _dynamicStep("2", "SUMA VISITAS", "Cada servicio realizado suma un punto en tu barra de progreso digital."),
          _dynamicStep("3", "RECLAMA TU PREMIO", "Al completar 6 visitas, desbloqueas automáticamente una recompensa premium."),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10, height: 32),
          const Text("* Válido exclusivamente para servicios en sucursal.", style: TextStyle(color: Colors.white24, fontSize: 9, fontStyle: FontStyle.italic)),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _dynamicStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: GoogleFonts.sora(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white30, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final String name;
  final int visits;
  const _CardFront({required this.name, required this.visits});

  @override
  Widget build(BuildContext context) {
    String level = "BLACK"; Color levelCol = const Color(0xFF8B8B8B);
    if (visits >= 6) { level = "RED"; levelCol = AppColors.primary; }
    if (visits >= 15) { level = "ELITE"; levelCol = const Color(0xFFE5E4E2); }
    if (visits >= 30) { level = "LEGEND"; levelCol = const Color(0xFFFFD700); }

    return Container(
      height: 225, width: double.infinity,
      decoration: BoxDecoration(
        // FONDO LIGERAMENTE ROJO / GRADIENTE DE LUJO
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F), Color(0xFF2A0000)], // Tono rojo sutil al final
          stops: [0, 0.6, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: levelCol.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: levelCol.withValues(alpha: 0.1), blurRadius: 40),
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Stack(
        children: [
          Opacity(opacity: 0.05, child: Container(decoration: const BoxDecoration(image: DecorationImage(image: NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'), repeat: ImageRepeat.repeat)))),
          
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/images/logo.png', height: 70),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        FittedBox(child: Text(name.toUpperCase(), style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1))),
                        const SizedBox(height: 2),
                        Text("LEVEL • $level", style: GoogleFonts.sora(color: levelCol, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      ]),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIndicator(levelCol),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Reflejo animado
          Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.04), Colors.white.withValues(alpha: 0)], stops: const [0.45, 0.5, 0.55]))).animate(onPlay:(c)=>c.repeat()).shimmer(duration: 4.seconds)),
        ],
      ),
    );
  }

  Widget _buildIndicator(Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: (visits % 6) / 6, strokeWidth: 5, backgroundColor: Colors.white.withValues(alpha: 0.05), color: color)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text("${visits % 6}/6", style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          const Text("VISITAS", style: TextStyle(fontSize: 7, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  final String name;
  final String userId;
  const _CardBack({required this.name, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 225, width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D), 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("CAMIL", style: GoogleFonts.playfairDisplay(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)),
                const Text("ATELIER MEMBER", style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 3, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
                Text("ID: \${userId.substring(0, 12).toUpperCase()}", style: const TextStyle(color: Colors.white10, fontSize: 9)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 20)]),
              child: QrImageView(data: userId, version: QrVersions.auto, size: 100.0, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
