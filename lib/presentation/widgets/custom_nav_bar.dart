import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(Icons.home_outlined, 0),
                _navItem(Icons.content_cut_outlined, 1),
                _floatingCenterItem(), 
                _navItem(Icons.credit_card_outlined, 2), // BLACK CARD
                _navItem(Icons.history_outlined, 3),    // HISTORIAL (Citas)
                _navItem(Icons.person_outline, 4),      // PERFIL
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.white30, size: 22),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4, height: 4,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ).animate().scale(),
          ],
        ),
      ),
    );
  }

  Widget _floatingCenterItem() {
    return GestureDetector(
      onTap: () => onTap(99), // Código especial para BarberVision
      child: Container(
        height: 50, width: 50,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFC1121F), Color(0xFF780000)]),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 22),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 2.seconds, begin: const Offset(0.95, 0.95));
  }
}
