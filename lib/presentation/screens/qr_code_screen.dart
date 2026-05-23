import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/custom_button.dart';

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TU CÓDIGO QR', style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Muestra este código en caja para procesar tus productos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ).animate().fadeIn(),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: 'ORDEN_12345_CAMIL_43.00',
                  version: QrVersions.auto,
                  size: 250.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 48),
              const Text(
                'TOTAL A PAGAR',
                style: TextStyle(color: AppColors.textSecondary, letterSpacing: 2, fontSize: 12),
              ),
              const Text(
                '\$43.00',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 60),
              CustomButton(
                text: 'VOLVER A LA TIENDA',
                onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
